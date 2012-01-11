# -*- coding: utf-8 -*-
# This file is part of OpenRubyRMK.
# 
# Copyright © 2010 OpenRubyRMK Team
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
  class Karfunkel
    extend Pluggable
    
    #The version of the OpenRubyRMK, read from the version file.
    VERSION = OpenRubyRMK::Karfunkel::Paths::VERSION_FILE.read.chomp.freeze

    #The configuration options from both the commandline and the
    #configuration file as a hash (whose keys are symbols).
    attr_reader :config

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
      
      #This is where all configuration, i.e. both from commandline
      #options and from the configuration file, is stored in.
      @config = {}

      #Setup the base things. Most of these call hook methods,
      #but aren’t themselves hooks.
      load_raw_config
      load_plugins
      parse_config(@__raw_config)
      load_argv(argv)
      setup_signal_handlers

      #Add a constant referring to self as the one and only instance
      #of this class.
      #
      #Note I’m doing this rather than including Ruby’s Singleton module, because
      #the Singleton module doesn’t allow arguments to be passed to
      ##initialize. See http://redmine.ruby-lang.org/issues/5448.
      self.class.const_set(:THE_INSTANCE, self)
    end

    #The very heart of the plugin mechanism. This plugs a
    #module into Karfunkel. Called from #parse_config, but you can
    #call it later if you want to include plugins not found
    #by #load_plugins or just delay plugin loading.
    #==Parameter
    #[plugin] The Plugin instance to include.
    #==Example
    #  # Load the first registered plugin
    #  Karfunkel::THE_INSTANCE.load_plugin(Plugin.all.first)
    def load_plugin(plugin)
      self.class.send(:include, plugin) # Mixins for the world! ;-)
      @config[:plugins] << plugin
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

      #*HOOK*. This methods specifies how to handle configuration
      #directives in the configuration file. Note that the :plugin
      #directive is special, see #load_plugins in this file’s sourecode
      #for further explanation.
      #
      #This method doesn’t do anything by default.
      #==Parameter
      #[hsh] The content of the configuration file in form of a hash.
      #      Note that the keys are symbols, not strings.
      def parse_config(hsh)
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
    
    #Reads in the configuration file and converts the keys from strings
    #to symbols, but doesn’t interpret it.
    def load_raw_config
      unless Paths::CONFIG_FILE.file? and Paths::CONFIG_FILE.readable?
        raise("Can't read the configuration file at #{Paths::CONFIG_FILE}!")
      end
      @__raw_config = YAML.load_file(Paths::CONFIG_FILE.to_s)
      @__raw_config = Hash[@__raw_config.map{|k, v| [k.to_sym, v]}] #Symbolify the keys
    end

    #This method loads all the plugins found by #load_config and populates
    #the @config variable with them. This behaviour should be
    #in #parse_config as that’s the method supposed to fill @config (together
    #with #parse_argv), but that would cause a chicken-egg-problem, because
    #plugins are allowed to do their own configuration file parsing.
    def load_plugins
      @config[:plugins] = []
      
      @__raw_config[:plugins].each do |plugname|
        if plugin = Plugin[plugname] # Single = intended
          load_plugin(plugin)
        else
          raise("Plugin #{plugname} not found!")
        end
      end
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
