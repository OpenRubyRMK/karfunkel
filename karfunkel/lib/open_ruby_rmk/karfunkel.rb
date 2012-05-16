# -*- coding: utf-8 -*-
# This file is part of OpenRubyRMK.
# 
# Copyright © 2012 OpenRubyRMK Team
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
require "logger"
require "eventmachine"
require "nokogiri"
require "open_ruby_rmk/common" # `openrubyrmk-common' RubyGem

require_relative "karfunkel/paths"
require_relative "karfunkel/command_helpers"
require_relative "karfunkel/plugin"
require_relative "karfunkel/pluggable"
require_relative "karfunkel/errors"
require_relative "karfunkel/configuration"
require_relative "karfunkel/client"
require_relative "karfunkel/protocol"

module OpenRubyRMK

  #This is OpenRubyRMK’s server. Every GUI is just a
  #client to His Majesty Karfunkel.
  #
  #This class defines the basic functionality needed for
  #receiving and sending requests via an underlying EventMachine
  #reactor.
  #
  #== Plugins
  #
  #Karfunkel’s capabilities can easily extended by a set of
  #plugins, i.e. Ruby modules that are mixed into Karfunkel
  #himself and into other classes inside the +Karfunkel+
  #namespace.
  #
  #Writing a plugin is as easy as creating a module inside the
  #OpenRubyRMK::Karfunkel::Plugins namespace. As described above,
  #Karfunkel exposes some methods you can hook into and change or
  #add to Karfunkel’s acting. If for example you want to display
  #a nice starting message on the server side (whatever for) you
  #could do it like this:
  #
  #  module OpenRubyRMK::Karfunkel::Plugins::StartupMessagePlugin
  #    def start
  #      super
  #      puts("Hey, time to do some cool coding!")
  #    end
  #  end
  #
  #Note the call to +super+: This is important, because otherwise the
  #code of other plugins, maybe even _base_, would not be run.
  #
  #When you’ve finished writing your plugin, save it into the
  #*lib/open_ruby_rmk/karfunkel/plugins* directory. On startup,
  #Karfunkel will load any files it finds in that directory. Note
  #that files in subdirectories aren’t automatically recognized,
  #because you may find yourself needing multiple classes for
  #your plugins. Assuming you’re writing a plugin called
  #+MyPlugin+ that resides in a file called *my_plugin.rb* in
  #the above directory, you can then easily add a subdirectory
  #*plugins/my_plugin/* that is completely under your control,
  #Karfunkel’s loading won’t interfer with yours. See the
  #_base_ plugin for an example.
  #
  #Note however that your plugin (as the name suggests) is
  #_included_ into the OpenRubyRMK::Karfunkel class. Therefore,
  #if you define a class OpenRubyRMK::Karfunkel::Plugins::MyPlugin::SecretClass,
  #it will be available after loading your plugin as
  #OpenRubyRMK::Karfunkel::SecretClass. Please also beware you don’t
  #accidentally overwrite existing classes this way.
  #
  #If you add instance methods to your plugin module that didn’t
  #exist in any way before inside Karfunkel, the methods will
  #be available on the Karfunkel instance after loading your
  #plugin. After all, this is just a normal Ruby +include+.
  #
  #If you write a plugin and need to initialize it in some way,
  #you can use Ruby’s own Module#included hook.
  #
  #The magic allowing you to overwrite methods via #include (which
  #normally isn’t possible in Ruby) can be found inside the
  #OpenRubyRMK::Karfunkel::Pluggable module. If you want to use
  #that one in your own classes, you of course can do so.
  #
  #== Sub-plugins
  #
  #Beside Karfunkel itself, you can hook into some other classes
  #inside the Karfunkel namespace. This can be achieved by creating
  #a module named after the class you want to hook into, but inside
  #your plugin’s main module. So, if you wish to hook into the
  #OpenRubyRMK::Karfunkel::Configuration class, you can do so by
  #defining a plugin submodule
  #OpenRubyRMK::Karfunkel::Plugin::MyPlugin::Configuration
  #and overwrite the hook methods there in the same mannor you do
  #for the main Karfunkel class. These "sub-plugins" are automatically
  #recognised by #load_plugin and included in the proper classes.
  #
  #Following is a list of classes you may hook into by the sub-plugin
  #mechanism:
  #
  #* OpenRubyRMK::Karfunkel::Configuration
  class Karfunkel
    extend Pluggable
    
    #The version of the OpenRubyRMK, read from the version file.
    VERSION = OpenRubyRMK::Karfunkel::Paths::VERSION_FILE.read.chomp.freeze

    #This is the "client" ID Karfunkel himself uses.
    #TODO: Make this a configuration directive.
    ID = 0

    #The configuration options from both the commandline and the
    #configuration file as a hash (whose keys are symbols).
    attr_reader :config
    #The list of enabled plugins. Ruby Module instances.
    attr_reader :plugins
    #An array containing all clients to whom Karfunkel holds
    #connections. Client objects.
    attr_reader :clients
    #The instance of CommandProcessor that Karfunkel uses in order
    #to forward incoming requests and responses to the respective
    #plugins.
    attr_reader :processor
    #An array of all currently loaded projects.
    attr_reader :projects
    #The Logger instance used by the log_* methods.
    attr_reader :log
    #The currently selected project or +nil+ if no project has been
    #selected yet.
    attr_reader :selected_project

    #The one and only instance of Karfunkel, set after the call to ::new.
    #This is the same as directly referencing the THE_INSTANCE constant.
    def self.instance
      THE_INSTANCE
    end

    #Creates the one and only instance of Karfunkel. Yes, you
    #*cannot* call this method more than once per program, because
    #multiple running Karfunkels are nonsense entirely.
    #==Parameters
    #[argv] The commandline options you want Karfunkel to process.
    #       Note that the processing is mainly done by plugins,
    #       bare Karfunkel just understands a quite limited set
    #       of commandline options (see #parse_argv).
    #==Raises
    #[RuntimeError] You tried to call this method more than once.
    #==Return value
    #The one and only instance of this class.
    #==Remarks
    #This method sets a constants OpenRubyRMK::Karfunkel::THE_INSTANCE
    #which points to the created instance. You don’t have to keep
    #track of the instance therefore.
    def initialize(argv)
      raise("There can only be one instance of Karfunkel!") if self.class.const_defined?(:THE_INSTANCE)
      self.class.const_set(:THE_INSTANCE, self)

      # List of loaded plugins.
      @plugins = []
      # Configuration instance.
      @config = Configuration.new
      # Hold procs to handle incomming requests and responses
      @request_procs  = {}
      @response_procs = {}

      # Load the plugin files (this does NOT enable the plugins!)
      OpenRubyRMK::Karfunkel::Paths::PLUGIN_DIR.each_child do |path|
        require(path) if path.to_s.end_with?(".rb")
      end

      # Setup the base things. Most of these call hook methods,
      # but aren’t themselves hooks.
      load_plugins # Enables the plugins listed in the config file
      load_config
      load_argv(argv)
      setup_signal_handlers
      create_logger
    end

    #Evaluates the block in the context of the Configuration object
    #this object holds. This method is only called from the
    #configuraton file.
    #==Raises
    #[Errors::ConfigurationError]
    #  On any errors in the config.
    def configure(&block) # :nodoc:
      @config.instance_eval(&block)
      @config.check!
    end

    #The very heart of the plugin mechanism. This plugs a
    #module into Karfunkel. Called from #load_plugins, but you can
    #call it later if you want to include plugins not found
    #by #load_plugins or just delay plugin loading.
    #==Parameter
    #[plugin] The module to include.
    #==Example
    #  # Load the first registered plugin
    #  Karfunkel::THE_INSTANCE.load_plugin(Plugin.all.first)
    def load_plugin(plugin)
      # First include the plugin’s main module.
      self.class.send(:include, plugin)

      # If it contains sub-plugins for other hookable classes, include
      # them where they belong.
      Configuration.send(:include, plugin.const_get(:Configuration)) if plugin.const_defined?(:Configuration)

      # Remember we loaded this particular plugin.
      @plugins << plugin
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

    #Short description
    def to_s
      "Karfunkel"
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
      to = @clients.find{|c| c.id == to} unless to.kind_of?(OpenRubyRMK::Karfunkel::Client)
      raise("Client with ID #{to} couldn't be found!") unless to
      to.connection.send_data(to.connection.transformer.convert!(cmd) + OpenRubyRMK::Karfunkel::Protocol::END_OF_COMMAND)
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
      cmd = OpenRubyRMK::Common::Command.new(ID)
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
      cmd = OpenRubyRMK::Common::Command.new(ID)
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
      cmd = OpenRubyRMK::Common::Command.new(ID)
      cmd << note
      @clients.each do |client|
        deliver(cmd, client)
      end
    end

    #true if Karfunkel is running in debug mode.
    def debug_mode?
      @config[:debug_mode]
    end
    
    #true if the server has already been started.
    def running?
      @running
    end

    pluggify do

      #*HOOK*. This method starts Karfunkel. By default, it starts
      #EventMachine’s server.
      #==Raises
      #[RuntimeError] Karfunkel is already running.
      def start
        raise(RuntimeError, "Karfunkel is already running!") if @running
        @log.info("Starting up.")

        @log.info("This is Karfunkel, version #{OpenRubyRMK::Karfunkel::VERSION}.")
        if debug_mode?
          @log.warn("Running in DEBUG mode!")
          sleep 1 #Give time to read the above
          @log.debug("The configuration is as follows:")
          @config.each_pair{|k, v| @log.debug("#{k} => #{v.kind_of?(Proc) ? '<Codeblock>' : v}")}
        end

        @preparing_shutdown = false
        @clients            = []
        @projects           = []
        @selected_project   = nil
        @last_id            = 0

        @client_id_generator_mutex  = Mutex.new #Never generate duplicate client IDs.
        @request_id_generator_mutex = Mutex.new #Same for request IDs.

        Thread.abort_on_exception = true if debug_mode?

        @log.info("Loaded plugins: #{@plugins.map(&:to_s).join(', ')}")
        @log.info("A new story may begin now. Karfunkel waits with PID #$$ on port #{@config[:port]} for you...")
        EventMachine.start_server("localhost", @config[:port], OpenRubyRMK::Karfunkel::Protocol)
        @running = true
      end
      
      #*HOOK*. This method stops Karfunkel and disconnects all
      #clients.
      #==Raises
      #[RuntimeError] Karfunkel isn’t running.
      def stop(requestor = self)
        raise(RuntimeError, "Karfunkel is not running!") unless @running
        @log.info("Regular shutdown requested by #{requestor} (ID #{requestor.id}), informing connected clients.")
        
        #There’s no sense in waiting for clients when no clients are connected.
        return stop! if @clients.empty?
        
        req = OpenRubyRMK::Common::Request.new(generate_request_id, :Shutdown)
        req[:requestor] = requestor.id
        @clients.each do |client|
          client.accepted_shutdown = false #Clear any previous answers
          client.request(req)
        end
      end

      #*HOOK*. Handles an incomming request. By default, calls the
      #handler registered for the request’s type or errors out
      #if no handler is defined.
      #
      #If you just want to add new request types to Karfunkel in your
      #plugin, you should use the convenience methods
      #Plugin::ClassMethods#process_request and its response pedant
      #Plugin::ClassMethods#process_response. This hook only exists
      #to achieve an effect similar to so-called "middleware" in
      #popular application servers such as Rack[http://rack.rubyforge.org],
      #i.e. you can use this hook to inspect or even modify *all* requests
      #Karfunkel receives. If you want to modify the request, you should
      #advertise loading your plugin after other plugins, because those
      #loaded later are first called when processing a request.
      #
      #==Parameters
      #[client] The client that sent the request. A Client instance.
      #[req]    The request. A Request instance.
      #
      #==Raises
      #[Errors::UnknownRequestType]
      #  No handler defined for the request’s type
      #
      #==Example
      #The following is a super-simple example plugin that demonstrates
      #how to block any requests from clients not from the local network
      #(usually the 192.168.0.0/16 network block). Note that it is
      #not possible to use the convenience methods for delivering
      #responses by default as they’re only available on the module
      #level of a plugin, but not in the final Karfunkel instance. Hence
      #we have to construct and deliver the response manually by direct
      #use of the Response class and Karfunkel’s delivery methods.
      #
      #  module MyPlugin
      #    include OpenRubyRMK::Karfunkel::Plugin
      #
      #    def handle_request(client, req)
      #      unless client.ip.start_with?("192.168.")
      #        res = Common::Response.new(generate_request_id, :rejected, req)
      #        res[:reason] = "Not from the local network."
      #        deliver_response(req, client)
      #        # Note the missing call to super here! We have
      #        # already definitely answered the request here,
      #        # so no further processing is neither needed nor
      #        # desirable.
      #      else
      #        # Request from local network, everything OK.
      #        super
      #      end
      #    end
      #  end
      def handle_request(client, req)
        raise(Errors::UnknownRequestType.new(req, "Can't handle '#{req.type}' requests!")) unless can_handle_request?(req)

        @request_procs[req.type].call(client, req)
      end

      #*HOOK*. Handles an incoming response. By default, calls the
      #response handler registered for responses of a specific type.
      #If no handler is found, errors out.
      #
      #This hook is not intended to register new response handlers.
      #See #handle_request for a full discussion on this.
      #==Parameters
      #[client] The client the response came from. A Client instance.
      #[res]    The response the client sent. A Response instance.
      #==Raises
      #[Errors::UnknownResponseType]
      #  There’s no handler registered for responses to requests
      #  of this type.
      def handle_response(client, res)
        raise(Errors::UnknownResponseType.new(res, "Can't handle responses to '#{req.type}' requests!")) unless can_handle_response?(res)

        @response_procs[res.request.type].call(client, res)
      end
      
      protected

      #*HOOK*. This method parses the options passed to Karfunkel.
      #Bare Karfunkel understands the following options:
      #[-h] Display the help.
      #[-v] Display the version number.
      #Everything else is done by plugins.
      #==Parameter
      #[op] An OptionParser instance you can tweak around in
      #     your plugin. Please don’t remove anything already
      #     in there.
      def parse_argv(op)
        op.banner = "Karfunkel, OpenRubyRMK's server."

        op.on("-h",
              "--help",
              "Display this message and exit.") do
          puts op
          exit
        end
        
        op.on("-v",
              "--version",
              "Print version and exit.") do
          puts "This is OpenRubyRMK's Karfunkel, version #{OpenRubyRMK::VERSION}."
          exit
        end

        op.on("-d", "--[no-]debug",
              "Show debugging information on run. Assumes -L0.") do |bool|
          @config[:debug_mode] = true
        end
        
        op.on("-L", "--loglevel LEVEL",
              "Set the logging level to LEVEL.") do |level|
          @config[:log_level] = level
        end

        op.on("-n", "--changed",
              "Print out all config options different from the",
              "default values and exit.") do
          @config.each_changed_pair do |option, value|
            puts "#{option} => #{value.kind_of?(Proc) ? '<Codeblock>' : value}"
          end
          exit
        end
      end

      #*HOOK*. Sets up handlers for the following UNIX process signals:
      #[SIGINT]  Request a shutdown, asking all clients for agreement.
      #[SIGTERM] Force a shutdown, don’t ask the clients.
      #[SIGUSR1] Only available in debug mode. Enter IRB on the server side.
      def setup_signal_handlers
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

    end # pluggify

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

    #true if Karfunkel or one of its plugins is capable to
    #process a request of the given type.
    #==Parameter
    #[type] The name of the request type to handle or a Request
    #       instance.
    #==Return value
    #Either true or false.
    def can_handle_request?(type)
      type = type.type if type.kind_of?(OpenRubyRMK::Common::Request)
      @request_procs.has_key?(type)
    end

    #true if Karfunkel or one of its plugins is capable to
    #process a response to a request of the given type.
    #==Parameter
    #[type] The name of the response’s request type to handle or a Response
    #       instance.
    #==Return value
    #Either true or false.
    def can_handle_response?(type)
      type = type.request.type if type.kind_of?(OpenRubyRMK::Common::Response)
      @response_procs.has_key?(type)
    end

    #call-seq:
    #  define_request_handler(type){|request, client|...}
    #
    #Define a callback to be invoked when a request of the
    #given type occurs.
    #==Parameters
    #[type]    The type of the request.
    #[request] (*Block*) The current request to process.
    #[client]  (*Block*) The client sending the +request+.
    #==Raises
    #[Errors::PluginError]
    #  If you tried to define multiple handlers for a single
    #  request type.
    def define_request_handler(type, &handler)
      # Only one request handler per request type is allowed
      # in order to avoid confusion.
      raise(Errors::PluginError, "Duplicate definition of request handler '#{type}'!") if can_handle_request?(type)

      @request_procs[type] = handler
    end

    #call-seq:
    #  define_response_handler(type){|response, client|...}
    #
    #Define a callback to be invoked when a response to a request
    #of the given type occurs.
    #==Parameters
    #[type] The type of the request this response belongs to.
    #[response] (*Block*) The Response object representing the
    #           current response.
    #[client]   (*Block*) The client making the +response+.
    #==Raises
    #[Errors::PluginError]
    #  If you tried to define multiple handlers for responses
    #  of a specific type.
    def define_response_handler(type, &handler)
      # Only one response handler per response type is
      # allowed in order to avoid confusion.
      raise(Errors::PluginError, "Duplicate definition of response handler '#{type}'!") if can_handle_response?(type)

      @response_procs[type] = handler
    end
    
    private

    #Calls the hook method for the OptionParser (#parse_argv)
    #and then passes +argv+ into it.
    def load_argv(argv)
      op = OptionParser.new
      parse_argv(op)
      op.parse!(argv)
    end

    #This method loads all the plugins listed in the plugins file
    #and populates the @plugins variable with them.
    def load_plugins
      unless Paths::PLUGINS_FILE.file? and Paths::PLUGINS_FILE.readable?
        raise("Can't read the plugins file at #{Paths::PLUGINS_FILE}!")
      end

      File.open(Paths::PLUGINS_FILE).each_line do |plugname|
        next if plugname.strip.empty?     # Ignore empty lines
        next if plugname.start_with?("#") # Ignore comment lines

        if plugin = Plugin[plugname] # Single = intended
          load_plugin(plugin)
        else
          raise(Errors::ConfigurationError, "Plugin #{plugname} not found!")
        end
      end
    end

    #Evaluates the main configuration file (but doesn’t interpret
    #it, which is responsibility of the plugins).
    #Raises Errors::ConfigurationError if there’s an error evaluating the
    #file (this includes SyntaxErrors and similar, which are also rescued).
    def load_config
      load(Paths::CONFIG_FILE, true) # 2nd parameter: Wrap in anonymous module
    rescue Exception => e            # Config file may have syntax errors
      raise(Errors::ConfigurationError, "Configuration error: #{e.message}")
    end

    #Creates the logger.
    def create_logger
      @log                  = Logger.new($stdout)

      if debug_mode?
        $stdout.sync        = $stderr.sync = true
        @log.level          = Logger::DEBUG
        @config[:log_level] = 0 #Makes no sense otherwise
      else
        @log                = Logger.new($stdout)
        @log.level          = @config[:log_level]
      end

      @log.formatter        = @config[:log_format]
    end

  end

end
