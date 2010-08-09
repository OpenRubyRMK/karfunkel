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
      
      attr_reader :config
      attr_reader :mainwindow
      #The current project's root path. 
      attr_accessor :project_path
      #The last dir navigated into by a file open/save dialog. 
      #This is just for convenience, so that you don't have to 
      #navigate into the same dir again and again. 
      attr_accessor :remembered_dir
      
      def on_init
        load_config
        setup_localization
        
        @remembered_dir = Pathname.new(".").expand_path
        
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