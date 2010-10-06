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
require "wx"
require "drb"
require "timeout"
require "irb"
$VERBOSE = v

#Require the lib
require_relative "../lib/open_ruby_rmk"

module OpenRubyRMK
  
  #This is OpenRubyRMK's server. 
  class Karfunkel
    include DRbUndumped #We can't share the log's filhandle otherwise (it can't be marshalled)
    
    URI = "druby://127.0.0.1:3141".freeze
    #If we're running on Windows, use rubyw
    windows_add = "w" if RUBY_PLATFORM =~ /mswin|mingw/
    #Path to the Ruby executable. 
    RUBY = Pathname.new(RbConfig::CONFIG["bindir"] + File::SEPARATOR + RbConfig::CONFIG["ruby_install_name"] + windows_add)
    
    def initialize
      @uri = URI
      @started = false
      @loading = {:map_extraction => 0, :char_extraction => 0}
      
      OpenRubyRMK.setup
      
      @tempdirs = {
        :tempdir => OpenRubyRMK::Paths.tempdir, 
        :temp_mapsets_dir => OpenRubyRMK::Paths.temp_mapsets_dir, 
        :temp_characters_dir => OpenRubyRMK::Paths.temp_characters_dir
      }
      
      @project_dirs = {
        :project_path => OpenRubyRMK::Paths.project_path, 
        :project_mapsets_dir => OpenRubyRMK::Paths.project_mapsets_dir, 
        :project_maps_dir => OpenRubyRMK::Paths.project_maps_dir, 
        :project_characters_dir => OpenRubyRMK::Paths.project_chars_dir
      }
      @allowed_pids = []
    end
    
    def start
      raise(RuntimeError, "Karfunkel is already running.") if @started
      $log.info("Starting Karfunkel, OpenRubyRMK's server.")
      @started = true
      DRb.start_service(@uri, self)
      $log.info("Running on #{@uri}.")
      DRb.thread.join
      @started = false
      $log.info("Stopped Karfunkel.")
    end
    
    def running?
      @started
    end
    alias started? running?
    
    def log
      $log
    end
    
    def tempdirs
      @tempdirs
    end
    
    def clear_tempdir
      OpenRubyRMK::Paths.clear_tempdir
    end
    
    def project_dirs
      @project_dirs
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
  
end