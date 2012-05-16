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

require_relative "karfunkel/plugin"
require_relative "karfunkel/pluggable"
require_relative "karfunkel/paths"
require_relative "karfunkel/errors"
require_relative "karfunkel/configuration"

module OpenRubyRMK

  #This is OpenRubyRMK's server. Every GUI is just a client to his majesty Karfunkel.
  #
  #Karfunkel is completely modular. That means, if you try to run
  #Karfunkel without any plugins (not even _core_) enabled, you
  #will see him exiting quite fast. To clarify: <b>Any action
  #Karfunkel is capable of is defined by plugins</b>. The bare
  #Karfunkel class defined here consists of just the bare minimum
  #that allows Karfunkel to actually _load_ plugins and give hook
  #methods where plugins can easily intercept. These methods are
  #marked in this documentation with *HOOK* at the beginning.
  #
  #== Writing a plugin
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
  #code of other plugins, maybe even _core_, would not be run.
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
  #Karfunkel’s loading won’t interfere with yours. See the
  #_core_ plugin for an example.
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

    #The configuration options from both the commandline and the
    #configuration file as a hash (whose keys are symbols).
    attr_reader :config
    #The list of enabled plugins. Ruby Module instances.
    attr_reader :plugins

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

      #Setup the base things. Most of these call hook methods,
      #but aren’t themselves hooks.
      load_plugins
      load_config
      load_argv(argv)
      setup_signal_handlers
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

    pluggify do

      #*HOOK*. This method starts Karfunkel. By default, it doesn’t
      #do anything, it’s behaviour is defined entirely through
      #plugins.
      def start
      end
      
      #*HOOK*. This method stops Karfunkel. However, by default it
      #(as well as #start) doesn’t do anything yet, it’s behaviour
      #is entirely defined through plugins.
      def stop
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
      end

      #*HOOK*. This method is intended to set up signal handlers
      #for the server (i.e. SIGTERM and the like). However, by
      #default it does nothing.
      def setup_signal_handlers
      end
      
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

  end

end

#Load the plugin modules (loaded after the above definitions,
#because things like the VERSION constant aren’t defined otherwise
#and a plugin can’t make use of them). This doesn’t include subdirectories,
#because plugins may store their own further classes in subdirectories.
OpenRubyRMK::Karfunkel::Paths::PLUGIN_DIR.each_child do |path|
  require(path)
end
