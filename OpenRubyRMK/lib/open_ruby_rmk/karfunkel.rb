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
require "rbconfig"
require "drb"
require "timeout"
require "tempfile"
require "logger"
require "irb"
require "wx"
$VERBOSE = v

#Require the lib
require_relative "../open_ruby_rmk"
require_relative "./paths"
require_relative "./errors"
require_relative "./map"
require_relative "./mapset"
require_relative "./map_field"
require_relative "./character"
require_relative "./option_handler"
require_relative "./open_ruby_rmkonsole"

module OpenRubyRMK
  
  #This is OpenRubyRMK's server. 
  class Karfunkel
    
    class Controller
      
      def initialize(karfunkel)
        @karfunkel = karfunkel
        @loading = {:map_extraction => 0, :char_extraction => 0}
        @allowed_pids = []
      end
      
      def remote_rmk
        OpenRubyRMK
      end
      
      def inspect
        "#<Karfunkel server controller, running with PID #$$>"
      end
      
      def running?
        @karfunkel.running?
      end
      alias started? running?
      
      def log
        $log
      end
      
      def load_project(project_dir)
        @loading = {:map_extraction => 0, :char_extraction => 0}
        @allowed_pids.clear
        @allowed_pids << spawn(RUBY, OpenRubyRMK::Paths::BIN_CLIENTS_DIR + "mapset_extractor_client.rb", @uri)      
        @allowed_pids << spawn(RUBY, OpenRubyRMK::Paths::BIN_CLIENTS_DIR + "char_extractor_client.rb", @uri)
      end
      
      def project_loaded?
        @loading.values.all?{|percent| percent >= 100}
      end
      
      def update_load_process(pid, process, new_val)
        if @allowed_pids.include?(pid)
          @loading[process] = new_val
        else
          $log.warn("Unauthorized PID #{pid} tried updating #{process} process.")
        end
      end
      
    end
    
    URI = "druby://127.0.0.1:3141".freeze #TODO: Read this from a config file
    #If we're running on Windows, use rubyw
    windows_add = RUBY_PLATFORM =~ /mswin|mingw/ ? "w" : ""
    #Path to the Ruby executable. 
    RUBY = Pathname.new(RbConfig::CONFIG["bindir"] + File::SEPARATOR + RbConfig::CONFIG["ruby_install_name"] + windows_add)
    
    def initialize
      #Every single class (and it's instances, of course) in the OpenRubyRMK module 
      #is not allowed to be marshalled via DRb. Everything has to happen on the server side. 
      OpenRubyRMK.constants.each do |sym|
        obj = OpenRubyRMK.const_get(sym)
        #Instances
        obj.send(:include, DRbUndumped) if obj.kind_of?(Class)
        #Classes (and modules) themselves
        obj.send(:extend, DRbUndumped) if obj.kind_of?(Module)
      end
      OpenRubyRMK.send(:extend, DRbUndumped)
      
      @uri = URI
      @started = false
      OpenRubyRMK.setup
    end
    
    def start
      raise(RuntimeError, "Karfunkel is already running.") if @started
      $log.info("Starting Karfunkel, OpenRubyRMK's server.")
      @started = true
      @controller = Controller.new(self)
      DRb.start_service(@uri, @controller)
      
      setup_signal_handlers
      
      $log.info("Running with PID #{$$} on #{@uri}.")
      DRb.thread.join
      @started = false
      $log.info("Stopped Karfunkel.")
    end
    
    def running?
      @started
    end
    alias started? running?
    
    private
    
    def setup_signal_handlers
      Signal.trap("SIGINT"){on_sigint}
      Signal.trap("SIGTERM"){on_sigterm}
    end
    
    def on_sigint
      $log.info("Cought SIGINT, exiting...")
      exit
    end
    
    def on_sigterm
      $log.info("Cought SIGTERM, exiting...")
      exit
    end
    
  end
  
end