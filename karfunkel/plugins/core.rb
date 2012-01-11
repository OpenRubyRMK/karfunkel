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

require "eventmachine"
require "nokogiri"
require "open_ruby_rmk/common" # 'openrubyrmk-common' RubyGem

#This is the core plugin that comes with the OpenRubyRMK’s server,
#Karfunkel. It provides the basic functionality of Karfunkel and
#hence shouldn’t be removed from your configuration’s plugin
#list unless you have written something equivalent.

OpenRubyRMK::Karfunkel::Plugin.new(:Core) do

  #This is the "client" id Karfunkel himself uses.
  ID = 0

  #An array containing all clients to whom Karfunkel holds
  #connections. Client objects.
  attr_reader :clients
  #An array of all currently loaded projects.
  attr_reader :projects
  #The Logger instance used by the log_* methods.
  attr_reader :log
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

  #(Hooked) Called when the plugin is activated. Monkeypatches
  #the Plugin class to allow easier plugin writing, notably for
  #processing requests.
  def self.included(klass)
    OpenRubyRMK::Karfunkel::Plugin.send(:include, OpenRubyRMK::Karfunkel::Plugin::Extensions)
  end

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

    @client_id_generator_mutex  = Mutex.new #Never generate duplicate client IDs.
    @request_id_generator_mutex = Mutex.new #Same for request IDs.

    create_logger
    Thread.abort_on_exception = true if debug_mode?

    @log.info("Loaded plugins: #{@config[:plugins].map(&:to_s).join(', ')}")
    @log.info("A new story may begin now. Karfunkel waits with PID #$$ on port #{@config[:port]} for you...")
    EventMachine.start_server("localhost", @config[:port], Karfunkel::Protocol)
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
    
    #There’s no sense to wait for clients when no clients are connected.
    return stop! if @clients.empty?
    
    req = Request.new(generate_request_id, :Shutdown)
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

  #(Hooked) Sets up handlers for the following UNIX process signals:
  #[SIGINT]  Request a shutdown, asking all clients for agreement.
  #[SIGTERM] Force a shutdown, don’t ask the clients.
  #[SIGUSR1] Only available in debug mode. Enter IRB on the server side.
  def setup_signal_handlers
    super
    Signal.trap("SIGINT") do
      @log.info("Cought SIGINT, going to shutdown...")
      stop
    end
    Signal.trap("SIGTERM") do
      @log.info("Cought SIGTERM, forcing shutdown...")
      stop!
    end
    Signal.trap("SIGUSR1") do
      if debug_mode?
        @log.debug("Cought SIGUSR1, loading IRB...")
        ARGV.clear #If there’s something in, IRB will run amok
        require "irb"
        IRB.start
        @log.debug("Finished IRB.")
      end
    end
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
  
  #Generates a new and unused client ID. 
  #==Return value
  #An integer.
  #==Example
  #  p OpenRubyRMK::Karfunkel::THE_INSTANCE.generate_client_id #=> 1
  #  p OpenRubyRMK::Karfunkel::THE_INSTANCE.generate_client_id #=> 2
  def generate_client_id
    @id_generator_mutex.synchronize do
      @last_id += 1
    end
  end

  #Generates a new and unused ID for use with requests sent
  #by Karfunkel.
  #==Return value
  #An integer.
  def generate_request_id
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

  #Sends a command to the given client.
  #==Parameters
  #[cmd] The OpenRubyRMK::Common::Command instance to deliver.
  #[to]  The target client, either a Client instance or an integer
  #       that is interpreted as the client ID.
  #==Example
  #  cmd = Common::Command.new(123)
  #  cmd << Common::Request.new(456, "Foo")
  #  Karfunkel::THE_INSTANCE.deliver(cmd, 4)
  #==Remarks
  #To send a command just containing a single request, response or
  #notification, you can use the respective #deliver_* methods of
  #this class which internally call this method.
  def deliver(cmd, to)
    to = @clients.find{|c| c.id == to} unless to.kind_of?(Karfunkel::Client)
    raise("Client with ID #{to} couldn't be found!") unless to
    to.connection.write(to.connection.transformator.convert!(cmd))
  end

  #Convenience method for creating a command consisting of a
  #singe request. The constructed command is passed to #deliver.
  #==Parameters
  #[req] The Request instance to add to the command.
  #[to]  See #deliver for explanation.
  #==Example
  #  req = Common::Request.new(123, "Foo")
  #  Karfunkel.deliver_request(req, 9)
  def deliver_request(req, to)
    cmd = Command.new(ID)
    cmd << req
    deliver(cmd, to)
  end

  #Convenience method for creating a command consisting of a
  #single response. The constructed command is passed to #deliver.
  #==Parameters
  #[res] The Response instance to add to the command.
  #[to]  See #deliver for explanation.
  #==Example
  #  res = Common::Response.new(123, "OK", somerequest)
  #  Karfunkel.deliver_response(res, 456)
  def deliver_response(res, to)
    cmd = Command.new(ID)
    cmd << res
    deliver(cmd, to)
  end

  #Convenience method for creating a command consisting of a
  #single notification. The constructed command is passed
  #to #deliver once for each client.
  #==Parameter
  #[note] The Notification instance to add to the command.
  #==Example
  #  note = Common::Notification.new(123, "foo")
  #  Karfunkel.deliver_notification(note)
  def deliver_notification(note)
    cmd = Command.new(ID)
    cmd << note
    @clients.each do |client|
      deliver(cmd, client)
    end
  end

  private

  #Hooked. Adds the -d (debug mode) and -L (loglevel) options.
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
  
  #Hooked. Adds the interpretation of the following configuration
  #file directives:
  #* :port
  #* :greet_timeout
  #* :loglevel
  #* :ping_interval
  #* :logdir
  #* :log_format
  def parse_config(hsh)
    super
    hsh.each_pair do |k, v|
      case k
      when :port          then @config[:port]          = v
      when :greet_timeout then @config[:greet_timeout] = v
      when :loglevel      then @config[:loglevel]      = v
      when :ping_interval then @config[:ping_interval] = v
      when :logdir        then @config[:logdir]        = Pathname.new(v)
      when :log_format    then @config[:log_format]    = v
      end
    end
  end

  #Creates the logger.
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

    @log = Logger.new($stdout)
    @log.level = Logger::DEBUG
    @log.formatter = lambda do |severity, time, progname, msg| 
      timestr = time.strftime(@config[:log_format])
      sprintf(timestr.gsub(/&(\w+)/, '%{\1}'), :sev => severity.chars.first, :pid => $$, :msg => msg) + "\n"
    end
    
    @log.info("This is Karfunkel, version #{OpenRubyRMK::Karfunkel::VERSION}.")
    if debug_mode?
      @log.warn("Running in DEBUG mode!")
      sleep 1 #Give time to read the above
      @log.debug("The configuration is as follows:")
      @config.each_pair{|k, v| @log.debug("-| #{k} => #{v}")}
    end
  end

end

# Require all the classes for this plugin
require_relative "core/plugin_extensions"
require_relative "core/protocol"
require_relative "core/client"
require_relative "core/requests_and_responses"
