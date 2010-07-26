#!/usr/bin/env ruby
#Encoding: UTF-8

module OpenRubyRMK
  
  module GUI
    
    class Application < Wx::App
      include Wx
      
      attr_reader :config
      attr_reader :mainwindow
      
      def on_init
        load_config
        setup_localization
        
        @mainwindow = MainFrame.new
        @mainwindow.show
      end
      
      def on_exit
        
      end
      
      private
      
      def setup_localization
        if @config["locale"] == "auto"
          R18n.from_env(LOCALE_DIR.to_s)
        else
          R18n.from_env(LOCALE_DIR.to_s, @config["locale"])
        end
      end
      
      def load_config
        @config = YAML.load_file(CONFIG_FILE)
      end
      
    end
    
  end
  
end