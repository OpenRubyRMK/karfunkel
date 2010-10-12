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

v, $VERBOSE = $VERBOSE, nil
require "bundler/setup"
require "pathname"
require "tempfile"
require "logger"
require "drb"
require "timeout"
require "irb"
require "wx"
require "r18n-desktop"
$VERBOSE = v

require_relative "../../open_ruby_rmk"
require_relative "../paths"
#Require the GUI lib
require_relative "../gui"
require_relative "../gui/windows/main_frame"
require_relative "../gui/windows/map_dialog"
require_relative "../gui/windows/mapset_window"
require_relative "../gui/windows/console_window"
require_relative "../gui/windows/properties_window"
require_relative "../gui/windows/threaded_progress_dialog"
require_relative "../gui/controls/terminal"
require_relative "../gui/controls/rmkonsole"
require_relative "../gui/controls/map_hierarchy"
require_relative "../gui/controls/map_grid"
require_relative "../plugins" #Not sure -- belongs this to the GUI or the core lib?

#I monkeypatch the Wx::Image class because the grid cell renderers of the 
#mapset window and the map need to display Wx::Images. Because I can't 
#derive from Wx::GridCellRenderer for whatever reason, I derived my 
#cell renderer from the Wx::GridCellStringRenderer. This one sadly expects 
#strings to render and if fed with a Wx::Image it throws a TypeError. 
#But fortunetaly, in best Ruby convention, it checks wheather the given 
#object responds to #to_str and if so, uses that return value as the string. 
#For this reason, I put in the #to_str method here, which simulates the 
#image was an empty string. 
class Wx::Image
  
  #Returns an empty string. Read in the above code to know why. 
  def to_str
    ""
  end
  
end

module OpenRubyRMK
  
  module Clients
    
    class GUIClient < Wx::App
      include Wx
      include R18n::Helpers
      
      CONFIG_FILE_NAME = "ORR-gui-client-rc.yml".freeze
      
      #The main GUI window, an instance of class OpenRubyRMK::GUI::Windows::MainFrame. 
      attr_reader :mainwindow
      #The current project's root path. 
      attr_accessor :project_path
      #The last dir navigated into by a file open/save dialog. 
      #This is just for convenience, so that you don't have to 
      #navigate into the same dir again and again. 
      attr_accessor :remembered_dir
      
      attr_reader :config
      attr_reader :connection
      
      #Returns the currently selected map or +nil+ if no map 
      #is selected (mostly the case if the root node has been selected). 
      def selected_map
        @mainwindow.instance_eval{@map_hierarchy.selected_map}
      end
      
      #Returns the position of the currently selected field on the mapset, 
      #a two-element array of form 
      #  [x, y]
      #. This doesn't contain any information on the used mapset; use 
      #  Wx::THE_APP.selected_map.mapset
      #in order to get the currently selected mapset. 
      #If no map is currently selected (see #selected_map), this method returns 
      #+nil+. If a map is selected, but the user hasn't selected a field on the 
      #mapset window yet, you'll get a <tt>[0, 0]</tt> array and finally, 
      #if everything is as it should be, you'll get the position of the field on the 
      #mapset that has been selected as a two-element array of this form: 
      #  [x, y]
      #. When working with this method, you can ignore the special <tt>[0, 0]</tt> 
      #array and just proceed as if you were processing a normal field position and 
      #in fact, you cannot distinguish this case from that one that arises when the 
      #users wants to draw the field at (0|0), which means that the first field 
      #of a mapset (that one in the upper-left corner) is some kind of default value. 
      def selected_mapset_field
        ary = @mainwindow.instance_eval{@mapset_window.selected_field}
        if selected_map.nil?
          nil
        elsif ary.all?{|v| v == -1}
          [0, 0]
        else
          ary
        end
      end
      
      #First method called by wxRuby when initializing the Graphical 
      #User Interface. 
      def on_init
        load_config
        connect_to_server
        initialize_remote_objects
        $log.info("Starting GUI.")
                
        setup_localization
        load_plugins
        
        Dir.chdir(@config["startup_dir"]) unless @config["startup_dir"] == "auto"
        
        @remembered_dir = Pathname.new(".").expand_path
        
        $log.info "Creating mainwindow."
        @mainwindow = GUI::Windows::MainFrame.new
        $log.info "OK. Let's show the GUI now!"
        @mainwindow.show
      end
      
      #Called once in an execution of the mainloop. If for a 
      #reason I am not able to image in any way in *our* 
      #great application this rare thing called an exception 
      #occures, this method displays it to the user in a 
      #hopefully friendly way. 
      def on_run
        super
      rescue => e
        $log.debug("GUI exception handler triggered.")
        $log.fatal(e.class.name + ": " + e.message)
        $log.fatal("Backtrace:")
        e.backtrace.each{|trace| $log.fatal(trace)}
        
        #Only show the first 5 entries of the backtrace to prevent extra large 
        #error windows. 
        str = ""
        if e.backtrace.size > 5
          str << e.backtrace.first(5).join("\n")
          str << "\n... (#{e.backtrace.size - 5} further traces) ...\n"
        else
          str << e.backtrace.join("\n")
        end
        
        msg = sprintf(t.errors.fatal, e.class.name, e.message, str)
        md = MessageDialog.new(@mainwindow, caption: e.class.name, message: msg, style: OK | ICON_ERROR)
        md.show_modal
        
        #I'd like to reraise the error here, but then it gets captured by 
        #the global rescue statement in OpenRubyRMK.rb. This is a 
        #TODO. 
        exit 3 #In contrast to 1 for the global exception handler, 2 for connection error
      end
      
      #The last method called by wxRuby before it yields control back 
      #to the code behind the Wx::App#main_loop call. 
      def on_exit
        super
        $log.info "Running plugins for :finish."
        Plugins[:finish].each(&:call)
        $log.info("Finished.")
      end
      
      private
      
      def load_config
        @config = YAML.load_file(OpenRubyRMK::Paths::CONFIG_DIR + CONFIG_FILE_NAME)
      end
      
      def connect_to_server
        DRb.start_service #Needed to receive DRbUndumped objects (non-marshallable objects)
        sleep 2 #Ensure Karfunkel is up and running
        try = 1
        
        begin
          @connection = DRbObject.new_with_uri("druby://" + @config["karfunkel_address"])
        rescue DRb::DRbConnError => e
          try += 1
          if try > @config["max_connection_tries"]
            $stderr.puts("Failed to connect #{@config["max_connection_tries"]} times. Exiting.")
            exit 2
          end
          $stderr.puts("Connection to Karfunkel failed. URI was druby://#{@config["karfunkel_address"]}.")
          $stderr.puts("Retrying in 2 seconds.")
          sleep 2
          retry
        end
        #Assign the remote OpenRubyRMK constant to a global variable. 
        #This has to reasons: 
        #1. It is easier to write $remote_rmk instead of 
        #   Wx::THE_APP.connection.remote_rmk all the time. 
        #2. It's faster. Without the global: 
        #    0. We want OpenRubyRMK::Paths::INSTALL_DIR
        #    1. Send request for OpenRubyRMK to Karfunkel
        #    2. Get answer.
        #    3. Send request for Paths to Karfunkel
        #    4. Get answer
        #    5. Send request for INSTALL_DIR to Karfunkel
        #    6. Get the desired Pathname object. 
        #   With the global:
        #    1. Send request for Paths to Karfunkel
        #    2. Get answer
        #    3. Send request for INSTALL_DIR to Karfunkel
        #    4. Get the desired Pathname object. 
        $remote_rmk = @connection.remote_rmk
      end
      
      def initialize_remote_objects
        $log = @karfunkel.log
      end
      
      #Checks the configuration and sets the R18n localization 
      #library accordingly. 
      def setup_localization
        $log.info "Detecting locale."
        if @config["locale"] == "auto"
          R18n.from_env(Paths::LOCALE_DIR.to_s)
        else
          R18n.from_env(Paths::LOCALE_DIR.to_s, @config["locale"])
        end
        $log.info "Detected " + r18n.locale.title + "."
      end      
      
      #Loads all plugins and runs the plugins for :startup 
      #immediately after that. 
      def load_plugins
        $log.info "Loading plugins."
        Plugins.load_plugins
        $log.info "Running plugins for :startup."
        Plugins[:startup].each(&:call)
      end
      
    end
    
  end
  
end
