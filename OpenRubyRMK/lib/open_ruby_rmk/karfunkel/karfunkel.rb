#!/usr/bin/env ruby
#Encoding: UTF-8

=begin
This file is part of OpenRubyRMK.

Copyright © 2010 OpenRubyRMK Team

OpenRubyRMK is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

OpenRubyRMK is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with OpenRubyRMK.  If not, see <http://www.gnu.org/licenses/>.
=end

#Require the lib
#require_relative "./karfunkel/project"
require_relative "../paths"
require_relative "./errors"
#require_relative "./map"
#require_relative "./mapset"
#require_relative "./map_field"
#require_relative "./character"
require_relative "./option_handler"
require_relative "./client"
require_relative "./controller"

module OpenRubyRMK
  
  #Namespace for Karfunkel, OpenRubyRMK's server.
  module Karfunkel
   
    #The version of OpenRubyRMK, read from the version file.
    VERSION = Paths::VERSION_FILE.read.chomp.freeze
    
    #This is OpenRubyRMK's server. Every GUI is just a client to his majesty Karfunkel.
    class Karfunkel
      
      #The URI Karfunkel listens for connections.
      attr_reader :uri
      #An array of Karfunkel::Project objects, each representing a project.
      attr_reader :projects
      attr_reader :cmd_args
      #The logfile. If a client logs to this Logger object, it should begin
      #it's message with something like <tt>[CLIENTNAME]</tt>, because the client's
      #log messages are easier to distinguish from Karfunkel's then.
      attr_reader :log
      #The parsed content of the configuration file.
      attr_reader :config
      #The port Karfunkel listens at. Can be set via the config file.
      attr_reader :port
      #The list of clients.
      attr_reader :clients
      
      #Initializes Karfunkel, i.e. does command-line argument parsing, config
      #file reading, logger creation and signal setup.
      #
      #This <b>does not</b> start Karfunkel. See #start for this.
      def initialize
        @controller = Controller.new(self)
        @running = false
        @do_stop = false
        @clients = []
        @projects = []
        
        parse_argv
        create_logger
        load_config
        setup_signal_handlers
        
        Thread.abort_on_exception = true if debug_mode?
        @port = @config["port"]
      end
      
      #Human-readable description of form
      #  #<OpenRubyRMK::Karfunkel, the OpenRubyRMK server, running with PID <PID here> at <URI here>.>
      def inspect
        "#<#{self.class} Karfunkel, the OpenRubyRMK server, running with PID #{$$} at #{@uri}.>"
      end
      
      #true if Karfunkel is running in debug mode.
      def debug_mode?
        @debug_mode
      end
      
      #true if any project is currently loaded.
      def has_project?
        !@projects.empty?
      end
      
      #true if the server has already been started.
      def running?
        @running
      end
      alias started? running?
      
      #Starts Karfunkel. If called after Karfunkel has already been started, raises
      #a RuntimeError.
      def start
        raise(RuntimeError, "Karfunkel is already running.") if @started
        @log.info("Starting Karfunkel, OpenRubyRMK's server.")
        @running = true
                
        @server = TCPServer.open(@port)
        @log.info("Running with PID #{$$} on port #{@port}.")
        loop do
          Thread.new(@server.accept) do |client_sock|
            addr = client_sock.peeraddr
            @log.info("Received a connection try from #{addr[2]} (#{addr[3]}).")
            
            client = Client.new(client_sock)
            @clients << client
            
            #Greeting
            begin
              @controller.establish_connection(client)
            rescue => e
              @log.error("Connection error on greeting: #{e.class.name}: #{e.message}")
              e.backtrace.each{|trace| @log.error(trace)}
              client.socket.close
              next #Kill this thread--break is not allowed in procs for whatever reason
            end
            @log.info("Client #{client} connected.")
            
            #Loop the connection now and await commands.
            begin
              @controller.handle_connection(client)
            rescue Errors::ConnectionFailed => e #This error is not recoverable
              @log.error("Fatal connection error on with client #{client}: ")
              @log.error("#{e.class.name}: #{e.message}")
              e.backtrace.each{|trace| @log.error(trace)}
            rescue => e #Recoverable errors
              @log.warn("Ignoring connection error with client #{client}: ")
              @log.warn("#{e.class.name}: #{e.message}")
              retry #This does not trigger the ensure clause
            ensure
              @log.info("Client #{client} disconnected.")
              client.socket.close
              @clients.delete(client)
            end
          end
          break if @do_stop
        end
        
        @running = false
        @log.info("Stopped Karfunkel.")
      end
      
      def stop
        return false if @do_stop
        @do_stop = true
      end
      
      #This is called by Karfunkel::Project.new whenever a new project
      #has been created. It registers the project with Karfunkel so that
      #it can be used by other clients.
      def register_project(project)
        @projects << project
      end
      
      private
      
      def parse_argv
        @cmd_args = OptionHandler.parse(ARGV)
        @debug_mode = @cmd_args[:debug]
      end
      
      def create_logger
        if debug_mode?
          $stdout.sync = $stderr.sync = true
          @log = Logger.new($stdout)
          @log.level = Logger::DEBUG
        elsif @cmd_args[:logfile].nil?
          Paths::LOG_DIR.mkpath unless Paths::LOG_DIR.directory?
          @log = Logger.new(Paths::LOG_DIR + "OpenRubyRMK.log", 5, 1048576) #1 MiB
          @log.level = @cmd_args[:loglevel] #returns WARN if -L is not set
        else
          @log = Logger.new(options[:logfile])
          @log.level = @cmd_args[:loglevel] #returns WARN if -L is not set
        end
        @log.datetime_format =  "%d.%m.%Y, %H:%M:%S Uhr "
        @log.info("Started.") #OK, not 100% correct, but how to log this before the logger was created?
      end
      
      def load_config
        @log.info "Loading configuration file."
        @config = YAML.load_file(Paths::CONFIG_FILE)
      end
      
      def setup_signal_handlers
        Signal.trap("SIGINT"){on_sigint}
        Signal.trap("SIGTERM"){on_sigterm}
      end
      
      def on_sigint
        @log.info("Cought SIGINT, exiting...")
        exit
      end
      
      def on_sigterm
        @log.info("Cought SIGTERM, exiting...")
        exit
      end
      
    end
    
  end
  
end
