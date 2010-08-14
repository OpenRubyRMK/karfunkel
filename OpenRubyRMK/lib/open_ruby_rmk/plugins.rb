#!/usr/bin/env ruby
#Encoding: UTF-8

module OpenRubyRMK
  
  #This module handles plugin integration. A plugin is a Ruby script that resides in 
  #OpenRubyRMK <i>plugins/</i> directory and it's contents will be loaded 
  #at several points of OpenRubyRMK's execution process. See the Plugs.plug_into 
  #method for more information on this. 
  #
  #In a plugin script, +self+ points to the Plugs module (via a module_eval construct) 
  #which allows to write Plugins in a kind of DSL, specified by the methods of the Plugs module. 
  #Inside the Plugs.plug_into method, +self+ again is redirected to something else, specified by the 
  #parameter given to the method. An example plugin script: 
  #  #Encoding: UTF-8
  #  #self is OpenRubyRMK::Plugins::Plugs here
  #  plug_into :mainwindow do
  #    #self is the mainwindow instance here
  #  end
  #  #self is OpenRubyRMK::Plugins::Plugs again
  module Plugins
    
    #This array contains the symbols in which you may plug your scripts into. 
    ALLOWED_PLUGIN_SYMBOLS = [:startup, :finish, :mainwindow, :mapset_window].freeze
    
    module Plugs
      
      #Call this method in a plugin script. It redirects +self+ inside the given block 
      #to something you specify through the symbol passed to this method. The full list of 
      #possible symbols is available via the OpenRubyRMK::Plugins::ALLOWED_PLUGIN_SYMBOLS 
      #array, or just here: 
    #  Symbol          | call time           | self points to
    #  ================+=====================+=========================================
    #  :startup        | Plugin load time    | OpenRubyRMK::Plugins::Plugs
    #  ----------------+---------------------+-----------------------------------------
    #  :mainwindow     | Mainwindow creation | The mainwindow instance
    #                  | time                | 
    #  ----------------+---------------------+-----------------------------------------
    #  :mapset_window  | Mapset window       | A mapset window instance
    #                  | creation time       | 
    #  ----------------+---------------------+-----------------------------------------
    #  :finish         | Shortly before exit | OpenRubyRMK::Plugins::Plugs
      def self.plug_into(sym, &block)
        Plugins.allowed?(sym)
        Plugins.plugged[sym] << block
      end
      
    end
    
    @plugged = Hash.new{|hsh, key| hsh[key] = []}
    
    #A hash containing all loaded plugins. Form is: 
    #  {:plug => [code_blocks]}
    def self.plugged
      @plugged
    end
    
    #Raises an ArgumentError if +sym+ isn't allowed as a plugin symbol. 
    def self.allowed?(sym)
      unless ALLOWED_PLUGIN_SYMBOLS.include?(sym)
        raise(ArgumentError, "You can't plug into #{sym}!")
      end
    end
    
    #Loads all files from the plugins/ directory via #module_eval. 
    def self.load_plugins
      #The second argument to #module_eval specified the file name to display in error messages. 
      Dir.glob(PLUGINS_DIR.join("**", "*.rb").to_s).each{|filename| Plugs.module_eval(File.read(filename), filename)} #TODO - someone knows a better way than evil eval?
    end
    
    #Returns an array of all codeblocks associated with the given symbol. 
    def self.[](sym)
      @plugged[sym]
    end
    
  end
  
end