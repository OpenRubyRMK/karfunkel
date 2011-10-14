# -*- coding: utf-8 -*-
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

module OpenRubyRMK::Karfunkel::Plugins::Core

  #This is the "client" id Karfunkel himself uses.
  ID = 0

  #An array containing all clients to whom Karfunkel holds
  #connections. Karfunkel::ServerManagement::Client objects.
  attr_reader :clients
  #An array of all currently loaded projects.
  attr_reader :projects
  
  #The currently selected project or +nil+ if no project has been
  #selected yet.
  attr_reader :selected_project

  ##
  # :method: log_debug
  #call-seq:
  #  log_debug(msg) ==> true
  #
  #Logs a DEBUG level message.
  
  ##
  # :method: log_info
  #call-seq:
  #  log_info(msg) ==> true
  #
  #Logs an INFO level message.
  
  ##
  # :method: log_warn
  #call-seq:
  #  log_warn(msg) ==> true
  #
  #Logs a WARN level message.
  
  ##
  # :method: log_error
  #call-seq:
  #  log_error(msg) ==> true
  #
  #Logs an ERROR level message.
  
  ##
  # :method: log_fatal
  #call-seq:
  #  log_fatal(msg) ==> true
  #
  #Logs a FATAL level message. Do not use this, it's for internal use.

  #(Hooked) Starts Karfunkel.
  #===Raises
  #[RuntimeError] Karfunkel is already running.
  #===Example
  #  OpenRubyRMK::Karfunkel::Karfunkel.start
  def start
    super
    raise(RuntimeError, "Karfunkel is already running!") if @running
    @preparing_shutdown = false
    @clients            = []
    @projects           = []
    @selected_project   = nil
    @last_id            = 0

    @id_generator_mutex         = Mutex.new #Never generate duplicate client IDs.
    @request_id_generator_mutex = Mutex.new #Same for request IDs.

    Thread.abort_on_exception = true if debug_mode?
    create_logger

    @log.info("A new story may begin now. Karfunkel waits with PID #{$$} on port #{@port} for you...")
    EventMachine.start_server("localhost", @config[:port], Protocol)
    @running = true
  end

  #(Hooked) Stops Karfunkel and disconnects all clients.
  #==Raises
  #[RuntimeError] Karfunkel isn't running.
  #==Example
  #  OpenRubyRMK::Karfunkel::Karfunkel.stop
  def stop(requestor = self)
    raise(RuntimeError, "Karfunkel is not running!") unless @running
    @log.info("Regular shutdown requested by #{requestor}, informing connected clients.")
    
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
  #Doesn’t call the plugins registered to the #stop hook as
  #well.
  def stop!
    raise("Karfunkel is not running!") unless @running
    EventMachine.stop_event_loop
    @running = false
  end

  #true if Karfunkel is running in debug mode.
  def debug_mode?
    $DEBUG || @config[:debug_mode]
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
    define_method("log_#{str}") do |msg|
      @log.send(str, msg)
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
  #    OpenRubyRMK::Karfunkel::THE_INSTANCE.log_exception(e, :warn)
  #  end
  #==Remarks
  #If the log level has been set to :debug, a backtrace will
  #also be logged.
  def log_exception(exception, level = :error)
    @log.send(level, "#{exception.class.name}: #{exception.message}")
    exception.backtrace.each do |trace|
      @log.debug(trace)
    end
  end
  
  #Generates a new and unused ID. These IDs are inteded for use
  #with clients.
  #==Return value
  #An integer.
  #==Example
  #  p OpenRubyRMK::Karfunkel::THE_INSTANCE.generate_id #=> 1
  #  p OpenRubyRMK::Karfunkel::THE_INSTANCE.generate_id #=> 2
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
  #  OpenRubyRMK::Karfunkel::THE_INSTANCE.projects << proj
  #  OpenRubyRMK::Karfunkel::THE_INSTANCE.select_project(proj)
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
  #[index] The index in the #projects array.
  #==Raises
  #[IndexError] Invalid index given.
  #==Example
  #  OpenRubyRMK::Karfunkel::THE_INSTANCE.select_project_by_index(3)
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

  #Hooked.
  def parse_argv(op)
    super
    
    op.on("-d", "--[no-]debug",
          "Show debugging information on run") do |bool|
      @config[:debug_mode] = true
    end
    
    op.on("-L", "--loglevel LEVEL",
          "Set the logging level to LEVEL.") do |level|
      @config[:loglevel] = level
    end
  end

  #Hooked.
  def parse_config(hsh)
    super
    case
    when hsh[:port]          then @config[:port]          = hsh[:port]
    when hsh[:greet_timeout] then @config[:greet_timeout] = hsh[:greet_timeout]
    when hsh[:loglevel]      then @config[:loglevel]      = hsh[:loglevel]
    when hsh[:ping_interval] then @config[:ping_interval] = hsh[:ping_interval]
    when hsh[:logdir]        then @config[:logdir]        = Pathname.new(hsh[:logdir])
    end
  end

  #Overwrites bare Karfunkel’s default logger with something
  #more useful.
  def create_logger
    if debug_mode?
      $stdout.sync       = $stderr.sync = true
      @log               = Logger.new($stdout)
      @log.level         = Logger::DEBUG
      @config[:loglevel] = 0 #Makes no sense otherwise
      @config[:logdir]   = "(none)" #Makes no sense otherwise
    else
      log_dir = @config[:logdir] ||= Paths::LOG_DIR
      log_dir.mkpath unless log_dir.directory?
      @log = Logger.new(log_dir + "karfunkel.log", 5, 1048576) #1 MiB
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

end
