# -*- coding: utf-8 -*-

module OpenRubyRMK

  class Karfunkel

    #Mixin module for plugins. Including this module automatically
    #registers it with the plugin mechanism (but doesn’t automatically
    #activate it) and extends it with the Plugin::ClassMethods module.
    #
    #The +core+ plugin extends this and the ClassMethods module
    #in some ways by including the OpenRubyRMK::Karfunkel::Plugin::Extensions
    #module, so be sure to look there as well to know what
    #you really get when including +Plugin+.
    module Plugin

      #When a module mixes in Plugin, this module is mixed
      #into its singleton class (#extend).
      module ClassMethods
        include OpenRubyRMK::Karfunkel::CommandHelpers

        #call-seq:
        #  name() → a_string
        #  to_s() → a_string
        #
        #The name of this plugin. Derived from calling Module#name
        #and downcasing the last element after all the namespaces,
        #e.g. a module named Foo::Bar::Baz will have a +name+ of
        #"baz" after it was extended with the ClassMethods module.
        def name
          str = super # Module#name
          str.split("::").last.downcase
        end
        alias to_s name

        protected

        ########################################
        # Plugin DSL

        #Defines a handler for the given request type.
        def process_request(type, &block)
          Karfunkel.instance.define_request_handler(type, &block)
        end

        #Defines a handler for the given response type.
        def process_response(type, &block)
          Karfunkel.instance.define_response_handler(type, &block)
        end

        #Your direct access to Karfunkel’s Logger instance.
        def log
          Karfunkel.instance.log
        end

        #Shortcut equivalent to:
        #  OpenRubyRMK::Karfunkel.instance
        def kf
          Karfunkel.instance
        end

      end

      @plugins = []

      #Modules including this mixin are obviously intended
      #to be a plugin, so add any including module to the
      #list of available plugins.
      def self.included(mod)
        mod.extend(ClassMethods)
        @plugins << mod
      end

      #All registered plugins. Note a registered
      #plugin != an activated plugin. The activated
      #plugins are available through Karfunkel#plugins.
      #Enabling a plugin is possible with Karfunkel#load_plugin.
      def self.all
        @plugins
      end

      #Checks whether or not a plugin with a specific name is available
      #for loading.
      #==Parameter
      #[name] The name of your plugin, either a symbol or a string. Note
      #       that this is case-sensitive.
      #==Return value
      #True or false.
      #==Examples
      #  Plugin.available?("Core") #=> true
      #  Plugin.available?(:Foo)   #=> false
      def self.available?(name)
        name = name.to_s
        @plugins.any?{|plugin| plugin.name.to_s == name}
      end

      #Searches through all registered plugins and returns the Plugin instance with
      #the given name if one is found.
      #==Parameter
      #[name] The name of your plugin, either a symbol or a string. Note that
      #       this is case-sensitive.
      #==Return value
      #If a matching plugin is found, an instance of this class. Otherwise,
      #returns +nil+.
      #==Examples
      #  Plugin[:core] #=> <OpenRubyRMK::Karfunkel::Plugin Core>
      #  Plugin["foo"] #=> nil
      def self.[](name)
        name = name.to_s
        @plugins.find{|plugin| plugin.name == name}
      end

    end #Plugin

  end #Karfunkel

end #OpenRubyRMK
