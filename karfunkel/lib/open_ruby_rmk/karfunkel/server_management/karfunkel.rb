# -*- coding: utf-8 -*-
# 
# This file is part of OpenRubyRMK.
# 
# Copyright © 2010,2011 OpenRubyRMK Team
# 
# OpenRubyRMK is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
# 
# OpenRubyRMK is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with OpenRubyRMK.  If not, see <http://www.gnu.org/licenses/>.

require "bundler/setup"
require "pathname"
require "rbconfig"
require "socket"
require "tempfile"
require "logger"
require "zlib"
require "nokogiri"
require "chunky_png" #Chunky bacon?!
require "eventmachine"
require "archive/tar/minitar"

#Additions to Ruby's Pathname class.
class Pathname
  
  #Dir.glob with Pathname objects. +str+ can be a Pathname,
  #but needs not to.
  def glob(str)
    Dir.glob(self.join(*str.to_s.split(/\/\\/))).map{|g| Pathname.new(g)}
  end
  
end

#Require the paths, as they’re needed for some constants
require_relative "../paths"

module OpenRubyRMK
  
  #The version of OpenRubyRMK, read from the version file.
  VERSION = OpenRubyRMK::Karfunkel::Paths::VERSION_FILE.read.chomp.freeze
  
  #Namespace of Karfunkel.
  module Karfunkel
    
    module ServerManagement
      
      #This is OpenRubyRMK's server. Every GUI is just a client to his majesty Karfunkel.
      #The whole server-client architecture Karfunkel deals with works as follows:
      #
      #The main component is the server. It's called Karfunkel and it's represented
      #by the OpenRubyRMK::Karfunkel::ServerManagement::Karfunkel module. For each Ruby process
      #there can only be one server running. Here all the information shared by all
      #clients is stored (e.g. the project list).
      #
      #Karfunkel listens on a port specified in the config file (port 3141 by default)
      #for connections. If he detects a connection try, he waits for the potential
      #client to send him the +hello+ request (see the commands_and_responses.rdoc file)
      #and if the client does so, Karfunkel assigns a free ID at him and sends it
      #to the client. If not, the connection is closed. Clients are represented by
      #the OpenRubyRMK::Karfunkel::ServerManagement::Client class and they store the information specific
      #to a single client, for instance the client's ID.
      #
      #The third and most important component is OpenRubyRMK::Karfunkel::ServerManagement::Protocol. This
      #is a mixin module that is automatically mixed into the connections
      #(EventMachine::Connection derivatives, anonymous classes) made. Each connection
      #has it's own instance and runs in it's own thread which means that you can
      #think of the Protocol module as the main component of a connection and
      #to make life easier and make the whole process easier to understand, think
      #of it as the representation of the connection between Karfunkel and a client.
      #It stores that only that information that is important for the connection,
      #which does not have any semantical relation to what Karfunkel or a Client object
      #stores. For example it stores a data buffer to allow commands to be send
      #as parts instead of a whole.
      #
      #So the whole process is as follows:
      #
      #1. Karfunkel starts and listens on a port.
      #2. A connection is made to that port. EventMachine instanciates an
      #   anonymous class and mixes in the Protocol module. All events that
      #   occur on the connection are handled by that anonymous class.
      #3. The Protocol#post_init method instanciates a Client object and
      #   makes Karfunkel reference it. This allows Karfunkel to keep track
      #   of which clients do what.
      #4. When a client sends a request, the connection's anonymous class
      #   handles it. It will query Karfunkel or the client object as
      #   the request requires. One or more responses are sent back over the wire.
      #5. If a client closes the connection, the anonymous connection class
      #   removes the references Client object from Karfunkel's list of clients.
      #   The now unreferenced connection and it's client get eventually GC'ed.
      #6. Karfunkel shuts down, diconnecting all remaining clients.
      #
      #==A note about thread safety
      #
      #Due to EventMachine’s heavy use of multithreading, you can
      #assume that the methods Karfunkel exposes are thread-safe.
      #To achieve this, a number of internal mutexes are used, but usually
      #you shouldn’t have to care about this.
      module Karfunkel
        
        #This is the ID Karfunkel himself uses.
        ID = 0
        
        class << self
          
          #An array containing all clients to whom Karfunkel holds
          #connections. Karfunkel::ServerManagement::Client objects.
          attr_reader :clients
          #An array of all currently loaded projects.
          attr_reader :projects
          #The overall options affecting Karfunkel's behaviour. This is a
          #hash merged from the configuration file and the command-line
          #arguments, where the latter override the former.
          attr_reader :config
          #The port Karfunkel listens at.
          attr_reader :port
          #The currently selected project or +nil+ if no project has been
          #selected yet.
          attr_reader :selected_project
          
          ##
          # :singleton-method: log_debug
          #call-seq:
          #  log_debug(msg) ==> true
          #
          #Logs a DEBUG level message.
          
          ##
          # :singleton-method: log_info
          #call-seq:
          #  log_info(msg) ==> true
          #
          #Logs an INFO level message.
          
          ##
          # :singleton-method: log_warn
          #call-seq:
          #  log_warn(msg) ==> true
          #
          #Logs a WARN level message.
          
          ##
          # :singleton-method: log_error
          #call-seq:
          #  log_error(msg) ==> true
          #
          #Logs an ERROR level message.
          
          ##
          # :singleton-method: log_fatal
          #call-seq:
          #  log_fatal(msg) ==> true
          #
          #Logs a FATAL level message. Do not use this, it's for internal use.
          
          #Starts Karfunkel.
          #===Raises
          #[RuntimeError] Karfunkel is already running.
          #===Example
          #  OpenRubyRMK::Karfunkel::Karfunkel.start
          def start
            raise(RuntimeError, "Karfunkel is already running!") if @running
            @preparing_shutdown = false
            @clients = []
            @projects = []
            @selected_project = nil
            @last_id = 0
            @log_mutex = Mutex.new #The log is a shared resource.
            @id_generator_mutex = Mutex.new #The ID generator as well.
            @request_id_generator_mutex = Mutex.new #For the request ID generator
            
            @config = {}
            parse_argv
            load_config
            create_logger
            setup_signal_handlers
            
            @port = @config[:port]
            Thread.abort_on_exception = true if debug_mode?
            
            @log.info("A new story may begin now. Karfunkel waits with PID #{$$} on port #{@port} for you...")
            EventMachine.start_server("localhost", @port, Protocol)
            @running = true
          end
          
          #Stops Karfunkel and disconnects all clients.
          #==Raises
          #[RuntimeError] Karfunkel isn't running.
          #==Example
          #  OpenRubyRMK::Karfunkel::Karfunkel.stop
          def stop(requestor = self)
            raise(RuntimeError, "Karfunkel is not running!") unless @running
            log_info("Regular shutdown requested by #{requestor}, informing connected clients.")
            
            req = Requests::Shutdown.new(self, next_request_id)
            req[:requestor] = requestor.id
            @clients.each do |client|
              client.accepted_shutdown = false #Clear any previous answers
              client.request(req)
            end
          end

          #Immediately stops Karfunkel, forcibly disconnecting
          #all clients. The clients are not notified about
          #the server shutdown. Use this method with care.
          def stop!
            raise(RuntimeError, "Karfunkel is not running!") unless @running
            EventMachine.stop_event_loop
            @running = false
          end

          #true if Karfunkel is running in debug mode.
          def debug_mode?
            @config[:debug]
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
          
          %w[debug info warn error fatal unknown].each do |str|
            define_method(:"log_#{str}") do |msg|
              @log_mutex.synchronize do
                @log.send(str, msg)
              end
            end
          end

          #Logs an exception.
          #==Parameters
          #[exception] The exception to log.
          #[level]     (:error) The level to log the exception at. One of:
          #            * :debug
          #            * :info
          #            * :warn
          #            * :error
          #            * :fatal
          #            Do not use :fatal, it’s for internal use.
          #==Example
          #  begin
          #    #Do something
          #  rescue => e
          #    OpenRubyRMK::Karfunkel::Karfunkel.log_exception(e, :warn)
          #  end
          #==Remarks
          #If the log level has been set to :debug, a backtrace will
          #also be logged.
          def log_exception(exception, level = :error)
            @log_mutex.synchronize do
              @log.send(level, "#{exception.class.name}: #{exception.message}")
              exception.backtrace.each do |trace|
                @log.debug(trace)
              end
            end
          end
          
          #Generates a new and unused ID. These IDs are inteded for use
          #with clients.
          #==Return value
          #An integer.
          #==Example
          #  p OpenRubyRMK::Karfunkel::Karfunkel.generate_id #=> 1
          #  p OpenRubyRMK::Karfunkel::Karfunkel.generate_id #=> 2
          def generate_id
            @id_generator_mutex.synchronize do
              @last_id += 1
            end
          end

          #Generates a new and unused ID for use with requests sent
          #by Karfunkel.
          #==Return value
          #An integer.
          def next_request_id
            @request_id_generator_mutex.synchronize do
              @last_req_id ||= 1
              @last_req_id += 1
            end
          end
          
          #Sets the active project.
          #==Parameter
          #[project] A OpenRubyRMK::Kafunkel::ProjectManagement::Project instance.
          #==Raises
          #[ArgumentError] The project wasn’t registed with Karfunkel.
          #==Example
          #  proj = OpenRubyRMK::Karfunkel::PM::Project.load("myproj.rmk")
          #  OpenRubyRMK::Karfunkel::Karfunkel.projects << proj
          #  OpenRubyRMK::Karfunkel::Karfunkel.select_project(proj)
          def select_project(project)
            if @projects.include?(project)
              @selected_project = project
            else
              raise(ArgumentError, "The project #{project} is not available.")
            end
          end

          #Makes a project selected by it’s +index+ in the +projects+ array
          #the active project.
          #==Parameter
          #[index] The index in the Karfunkel.projects array.
          #==Raises
          #[IndexError] Invalid index given.
          #==Example
          #  OpenRubyRMK::Karfunkel::Karfunkel.select_project_by_index(3)
          def select_project_by_index(index)
            proj = @projects[index]
            raise(IndexError, "No project with index #{index}!") if proj.nil?
            @selected_project = proj
          end
          
          #Returns Karfunkel's own client ID. The value of the ID constant, which
          #is normally 0.
          def id
            ID
          end
          
          #Human-readeble description.
          def inspect
            "#<#{self.class} I AM KARFUNKEL. THEE IS NOTHING.>"
          end

          #Register a Notification to be send to all connected clients. You shouldn’t
          #care about this method, it’s used internally be the request DSL’s #broadcast
          #method.
          #==Parameter
          #[note] A OpenRubyRMK::Karfunkel::ServerManagement::Notification instance.
          #==Remarks
          #The notification is not broadcasted immediately, but rather it’s added
          #to each client’s notification queue. It’s up to the client to finally
          #read that queue.
          def add_broadcast(note)
            @clients.each do |client|
              client.notification(note)
            end
          end
          
          private
          
          def parse_argv
            @config = OptionHandler.parse(ARGV)
          end
          
          def create_logger
            if debug_mode?
              $stdout.sync = $stderr.sync = true
              @log = Logger.new($stdout)
              @log.level = Logger::DEBUG
              @config[:logdir] = "(none)" #Makes no sense otherwise
              @config[:loglevel] = 0 #Makes no sense otherwise
            elsif @config[:stdout]
              @log = Logger.new($stdout)
              @config[:logdir] = "(none)" #Makes no sense otherwise
            elsif @config[:logdir] == "auto"
              Paths::LOG_DIR.mkpath unless Paths::LOG_DIR.directory?
              @config[:logdir] = Paths::LOG_DIR
              @log = Logger.new(Paths::LOG_DIR + "OpenRubyRMK.log", 5, 1048576) #1 MiB
              @log.level = @config[:loglevel]
            else
              @config[:logdir] = Pathname.new(@config[:logdir])
              @config[:logdir].mkpath unless @config[:logdir]
              @log = Logger.new(@config[:logdir] + "OpenRubyRMK.log", 5, 1048576) #1 MiB
              @log.level = @config[:loglevel]
            end
            @log.formatter = lambda{|severity, time, progname, msg| "#{severity.chars.first} [#{time.strftime('%d-%m-%Y %H:%M:%S')} ##$$] #{msg}\n"}
            @log.info("This is Karfunkel, version #{VERSION}.")
            if debug_mode?
              @log.warn("Running in DEBUG mode!")
              sleep 1 #Give time to read the above
              @log.debug("The configuration is as follows:")
              @config.each_pair{|k, v| @log.debug("-| #{k} => #{v}")}
            end
          end
          
          def load_config
            cfg = @config[:configfile] ? YAML.load_file(@config[:configfile]) : YAML.load_file(Paths::CONFIG_FILE)
            #Turn the keys to symbols
            cfg = Hash[cfg.map{|k, v| [k.to_sym, v]}]
            #Merge the config file's options into those given via the command-line,
            #but ensure that the command-line options are always preferred.
            @config.merge!(cfg){|key, old_val, new_val| old_val}
          end
          
          def setup_signal_handlers
            Signal.trap("SIGINT"){on_sigint}
            Signal.trap("SIGTERM"){on_sigterm}
            Signal.trap("SIGUSR1"){on_sigusr1}
          end
          
          def on_sigint
            @log.info("Cought SIGINT, exiting...")
            stop!
            exit
          end
          
          def on_sigterm
            @log.info("Cought SIGTERM, exiting...")
            stop!
            exit
          end
          
          def on_sigusr1
            return unless debug_mode?
            Karfunkel.log_debug("Cought SIGUSR1. Entering IRB.")
            ARGV.clear
            require "irb"
            IRB.start
            Karfunkel.log_debug("IRB session ended.")
          end
          
        end
        
      end
      
    end
    
  end
  
end

#Require the rest of the lib
require_relative "../errors"
require_relative "../project_management"
require_relative "../project_management/map"
require_relative "../project_management/mapset"
require_relative "../project_management/map_field"
require_relative "../project_management/character"
require_relative "../project_management/project"

require_relative "../server_management"
require_relative "./client"
require_relative "./protocol"
require_relative "./command"
require_relative "./request"
require_relative "./response"
require_relative "./notification"

require_relative "./option_handler"

#Require all files in the requests directory
Dir.glob(File.join(File.dirname(__FILE__), "requests", "*.rb")).each do |f|
  require_relative f
end
