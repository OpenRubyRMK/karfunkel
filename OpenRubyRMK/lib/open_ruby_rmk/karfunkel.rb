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
require_relative "./karfunkel/project"
require_relative "../open_ruby_rmk"
require_relative "./paths"
require_relative "./errors"
require_relative "./map"
require_relative "./mapset"
require_relative "./map_field"
require_relative "./character"
require_relative "./option_handler"

module OpenRubyRMK
  
  #Namespace for Karfunkel, OpenRubyRMK's server.
  module Karfunkel
   
    #This is OpenRubyRMK's server. Every GUI is just a client to his majesty Karfunkel.
    class Karfunkel
      include Singleton #There's only ONE to rule 'em all
      
      URI = "druby://127.0.0.1:3141".freeze #TODO: Read this from a config file
      
      #The URI Karfunkel listens for connections.
      attr_reader :uri
      #An array of Karfunkel::Project objects, each representing a project.
      attr_reader :projects
      attr_reader :cmd_args
      #The logfile. If a client logs to this Logger object, it should begin
      #it's message with something like <tt>[CLIENTNAME]</tt>, because the client's
      #log messages are easier to distinguish from Karfunkel's then.
      attr_reader :log
      attr_reader :config
      
      #The following is a hack. Ruby's singleton.rb doesn't honour arguments
      #passed to initialize, but I do need this. So I just override the
      #default #instance method here.
      class << self # :nodoc:
        alias _old_instance instance
        
        def instance(uri = nil)
          inst = _old_instance
          if inst.uri.nil? #If no URI has been set yet, this ought to call #_initialize (with arguments!)
            raise(ArgumentError, "You didn't specify the URI to start at!") if uri.nil?
            inst.send(:_initialize, uri)
          else #If an URI has already been set, we don't want a second one!
            raise(ArgumentError, "Karfunkel is already initialized, you don't have to specify a URI!") unless uri.nil?
          end
          inst
        end
        
      end
      
      #Initializes Karfunkel. Pass in the URI where you want Karfunkel
      #to listen at.
      #
      #This <b>does not</b> start Karfunkel. See #start for this.
      #
      #It's named _initialize, because it is called by a hacked version of
      #Singleton.instance. See above code for explanation (not visible in RDoc,
      #you have to look into the sourcecode).
      def _initialize(uri) # :new:
        @uri = uri
        @started = false
        @projects = []
        
        parse_argv
        create_logger
        load_config
        setup_signal_handlers
        
        Thread.abort_on_exception = true if debug_mode?
      end
      private :_initialize
      
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
        @started
      end
      alias started? running?
      
      #Starts Karfunkel. If called after Karfunkel has already been started, raises
      #a RuntimeError.
      def start
        raise(RuntimeError, "Karfunkel is already running.") if @started
        @log.info("Starting Karfunkel, OpenRubyRMK's server.")
        @started = true
        
        #TODO: Implement network service here
        #@log.info("Running with PID #{$$} on #{uri}.")
        
        @started = false
        @log.info("Stopped Karfunkel.")
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
          LOG_DIR.mkpath unless LOG_DIR.directory?
          @log = Logger.new(LOG_DIR + "OpenRubyRMK.log", 5, 1048576) #1 MiB
          @log.level = options[:loglevel] #returns WARN if -L is not set
        else
          @log = Logger.new(options[:logfile])
          @log.level = options[:loglevel] #returns WARN if -L is not set
        end
        @log.datetime_format =  "%d.%m.%Y, %H:%M:%S Uhr "
        @log.info("Started.") #OK, not 100% correct, but how to log this before the logger was created?
      end
      
      def load_config
        @log.info "Loading configuration file."
        @config = YAML.load_file(CONFIG_FILE)
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
