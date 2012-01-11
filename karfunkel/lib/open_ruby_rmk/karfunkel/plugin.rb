# -*- coding: utf-8 -*-

module OpenRubyRMK

  class Karfunkel

    #A plugin is nothing else than a normal Ruby module (note this class
    #actually *inherits* from Rubys standard +Module+ class!) with some
    #extra information regarding Request and Response processing.
    #
    #As they’re just normal (and anonymous) modules, you can do anything with a Plugin
    #that is possible with normal Ruby modules: Define instance methods
    #in them (they will be available in the +Karfunkel+ class’ instance), include
    #them into other classes/modules (namely +Karfunkel+) or do the
    #<tt>kind_of?(Module)</tt> check.
    #
    #== Method scope summary
    #As using this class may cause headache regarding where defined methods
    #finally show up, here’s a summary.
    #
    #=== Class methods
    #Things you define via <tt>def Plugin.xxx</tt> or inside the class body
    #with <tt>def self.xxx</tt> are methods of the +Plugin+ *class*. Any
    #Plugin instance won’t be bothered with them.
    #
    #=== Instance methods
    #Things you define via <tt>def xxx</tt> inside this class’ body are instance
    #methods of +Plugin+, that is, these methods will be available to any
    #new Plugin (which is a normal Ruby module!) instance created with
    #<tt>OpenRubyRMK::Karfunkel::Plugin.new(:xxx)</tt>.
    #
    #=== Module methods of plugins
    #Things you define via <tt>def self.xxx</tt> inside a plugin’s scope,
    #i.e. inside the block you pass to this class’ ::new method or external
    #definitions à la
    #
    #  p = OpenRubyRMK::Karfunkel::Plugin.new(:xxx)
    #  def p.xxx
    #    #...
    #  end
    #
    #are module methods of the respective plugin; they won’t be available to
    #the +Plugin+ class itself, only to the created plugin module.
    #
    #=== Instance methods of plugins
    #Things you define via <tt>def xxx</tt> inside a plugin’s scope, e.g. in
    #the block pass to this class’ ::new method (see also the above explanations)
    #are instance methods of the respective plugin module and neither available
    #to the +Plugin+ class nor the plugin’s class. They are treated the same way
    #(and indeed they *are* the same) as normal Ruby modules’ instance methods, i.e.
    #the only way to access them is to include them into a class such as the
    #OpenRubyRMK::Karfunkel.
    #
    #== Reasoning
    #Subclassing +Module+ seems awkward on the first glance. It makes however from
    #both the theoretical and practical points of view absolutely sense. From the
    #practical side, the advantage is obvious: We have a completely autonomic class
    #for plugins with all advanteges of object-oriented classes, but it’s easily
    #possible with Ruby’s builtin mixin mechanism to include these "plugins" into
    #a class.
    #
    #From the theoretical side, we now have an own class explicetely for plugins,
    #which in an object-oriented world makes definitely sense. Furthermore,
    #often Ruby modules are recommended for plugins due to Ruby’s builtin mixin
    #mechanism--and, more importantly, a plugin actually _is_ a kind of module,
    #as it encapsulates a certain functionality that can easily be added to or
    #removed from a modular composed piece of software.
    class Plugin < Module

      @plugins = []

      #All registered Plugin instance. Note a registered
      #plugin != an activated plugin.
      def self.all
        @plugins
      end

      #Register a Plugin instance, making it available for
      #activation. Just registering it as a *possible* plugin
      #doesn’t mean *automatically* that it is activated, though.
      def self.register(plugin)
        @plugins << plugin
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
      #  Plugin[:Core] #=> <OpenRubyRMK::Karfunkel::Plugin Core>
      #  Plugin["Foo"] #=> nil
      def self.[](name)
        name = name.to_s
        @plugins.find{|plugin| plugin.name.to_s == name}
      end

      #call-seq:
      #  extend_plugin(name){...}
      #  extend_plugin(name){|plugin|...}
      #
      #This method is useful for splitting up your plugin into multiple
      #files. As you have to close the block passed to ::new when switching
      #to another file, you loose the DSL scope and would have to construct
      #all the necessary things yourself without the plugin DSL. This method
      #allows you to reenter the scope of your plugin after already having
      #closed the block for ::new.
      #
      #The block semantics are the same as for ::new, i.e. if you define a
      #block parameter, no scope changes happen, if you don’t, they do.
      #==Parameters
      #[name]   The name of the plugin you want to re-edit. Should be the exact
      #         same name you passed to ::new.
      #[plugin] (Blockargument) The plugin you wanted.
      #==Raises
      #[ArgumentError] +name+ is not a valid plugin name.
      #==Example
      #  OpenRubyRMK::Karfunkel::Plugin.extend_plugin(:foo) do
      #    process_request(:FooBar){...}
      #  end
      def self.extend_plugin(name, &block)
        if plugin = self[name] # Single = intended
          if block.arity.zero?
            plugin.instance_eval(&block)
          else
            block.call(plugin)
          end
        else
          raise(ArgumentError, "Plugin not found: #{name}!")
        end
      end

      #call-seq:
      #  new(name)                → a_plugin
      #  new(name){...}           → a_plugin
      #  new(name){|a_plugin|...} → a_plugin
      #
      #Creates a new (anonymous) module the same way Ruby’s <tt>Module.new</tt> does.
      #Addtionally, some initialization regarding Karfunkel’s plugin mechanism is
      #done. If called with a block without block parameters, changes the scope into
      #the newly created instance (+self+) so you can directly do your method definitions
      #in there. If called with a block with parameters, doesn’t change the scope
      #but rather yields +self+.
      #==Parameters
      #[name]          The name of your plugin, a symbol such as :MyPlugin. CamelCase names
      #                preferred, but not required. Do not confuse this with a Ruby module
      #                name (remember: To create "module names" you must assign the module
      #                to a constant--this is however not recommended for Plugin instances).
      #[dont_register] (false) Normally, created Plugin instances are automatically made
      #                available for activation via ::register. If this parameter is set
      #                to +true+, this won’t be done and you have to manually call ::register
      #                to make your plugin available for activation.
      #[a_plugin]      (Blockargument) +self+.
      #==Return value
      #The newly created instance.
      #==Examples
      #  # Regular usecase
      #  Plugin.new(:MyPlugin) do
      #    def start
      #      super
      #      puts "I hooked Karfunkel's #start method!"
      #    end
      #  end
      #  
      #  # Without scope changing
      #  Plugin.new(:MyPlugin) do |plugin|
      #    plugin.instance_eval{define_method(:start){puts("I hooked Karfunkel's #start method!")}}
      #  end
      #  
      #  # Without a block
      #  plugin = Plugin.new(:MyPlugin)
      #  plugin.instance_eval{define_method(:start){puts("I hooked Karfunkel's #start method!")}}
      #
      #  # Register the plugin manually
      #  plugin = Plugin.new(:MyPlugin, true){...}
      #  Plugin.register(plugin)
      #==Remarks
      #Note that creating an instance of this class doesn’t automactically
      #register your new plugin with Karfunkel.
      def initialize(name, dont_register = false, &block)
        super()
        @name = name
        
        if block_given?
          if block.arity.zero?
            instance_eval(&block)
          else
            block.call(self)
          end
        end

        self.class.register(self) unless dont_register
      end

      #Human-readable description of form:
      #  #<OpenRubyRMK::Karfunkel::Plugin <PluginName>>
      def inspect
        "#<#{self.class} #@name>"
      end

    end #Plugin

  end #Karfunkel

end #OpenRubyRMK
