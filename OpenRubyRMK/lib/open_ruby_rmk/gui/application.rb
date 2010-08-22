#!/usr/bin/env ruby
#Encoding: UTF-8

=begin
This file is part of OpenRubyRMK. 

Copyright © 2010 OpenRubyRMK Team

OpenRubyRMK is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

OpenRubyRMK is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with OpenRubyRMK.  If not, see <http://www.gnu.org/licenses/>.
=end

module OpenRubyRMK
  
  module GUI
    
    class Application < Wx::App
      include Wx
      include R18n::Helpers
      
      attr_reader :config
      attr_reader :mainwindow
      attr_reader :id_generator
      #The current project's root path. 
      attr_accessor :project_path
      #The last dir navigated into by a file open/save dialog. 
      #This is just for convenience, so that you don't have to 
      #navigate into the same dir again and again. 
      attr_accessor :remembered_dir
      
      def on_init
        load_config
        setup_localization
        load_plugins
        
        @remembered_dir = Pathname.new(".").expand_path
        
        $log.info "Creating mainwindow."
        @mainwindow = Windows::MainFrame.new
        $log.info "OK. Let's show the GUI now!"
        @mainwindow.show
      end
      
      def on_run
        super
      rescue => e
        $log.fatal(e.class.name + ": " + e.message)
        $log.fatal("Backtrace:")
        e.backtrace.each{|trace| $log.fatal(trace)}
        
        msg = sprintf(t.errors.fatal, e.class.name, e.message, e.backtrace.join("\n"))
        md = MessageDialog.new(@mainwindow, caption: e.class.name, message: msg, style: OK | ICON_ERROR)
        md.show_modal
        
        #I'd like to reraise the error here, but then it get's captured by 
        #the global rescue statement in OpenRubyRMK.rb. This is a 
        #TODO. 
        exit 2 #In contrast to 1 for the global exception handler
      end
      
      def on_exit
        $log.info "Running plugins for :finish."
        Plugins[:finish].each(&:call)
      end
      
      private
      
      def setup_localization
        $log.info "Detecting locale."
        if @config["locale"] == "auto"
          R18n.from_env(LOCALE_DIR.to_s)
        else
          R18n.from_env(LOCALE_DIR.to_s, @config["locale"])
        end
        $log.info "Detected " + r18n.locale.title + "."
      end
      
      def load_config
        $log.info "Loading configuration file."
        @config = YAML.load_file(CONFIG_FILE)
      end
      
      def load_plugins
        $log.info "Loading plugins."
        Plugins.load_plugins
        $log.info "Running plugins for :startup."
        Plugins[:startup].each(&:call)
      end
      
    end
    
  end
  
end