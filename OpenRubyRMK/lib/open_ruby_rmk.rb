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

#External requires
if RUBY_VERSION >= "1.9.2"
  #For whatever reasion, Psych's compatibility doesn't include YAML::PrivateType, 
  #causing R18n to crash. As soon as I have Internet access again, I'll file a bug. 
  #require "psych"
  #YAML = Psych
  require "yaml"
else
  require "yaml"
end
require "tempfile"
require "logger"
require "optparse"
require "pathname"
require "zlib"
require "archive/tar/minitar"
require "r18n-desktop"
require "pp"

#This is the namespace of the OpenRubyRMK library. 
#Please note the word "project" always refers to games 
#created with OpenRubyRMK. If we refer to OpenRubyRMK 
#itself, we spell out the full name "OpenRubyRMK". 
module OpenRubyRMK
  
  #The version of the OpenRubyRMK lib you're using. 
  VERSION = "0.0.1-dev (10.9.10)".freeze
  
  #OpenRubyRMK's root dir. This is *not* the root dir of a game 
  #created with OpenRubyRMK, but refers to OpenRubyRMK's 
  #installation directory. On Windows, it's the temporary directory 
  #created by OCRA. 
  ROOT_DIR = Pathname.new(__FILE__).dirname.parent.expand_path
  #OpenRubyRMK's real installation directory. On Windows, this is the 
  #directory where OpenRubyRMK was installed to (in contrast to ROOT_DIR). 
  #On other systems, this is the same as ROOT_DIR. 
  INSTALL_DIR = ENV.has_key?("OCRA_EXECUTABLE") ? Pathname.new(ENV["OCRA_EXECUTABLE"].tr("\\", "/")).parent.parent : ROOT_DIR #OCRA_EXECUTABLE is defined for Windows *.exe files
  #Directory where GUI icons etc. are found. 
  DATA_DIR = ROOT_DIR + "data"
  #The directory where log files are created in. 
  LOG_DIR = INSTALL_DIR + "bin" + "logs"
  #This directory contains OpenRubyRMK's translation files. 
  LOCALE_DIR =  INSTALL_DIR + "locale"
  #This is the path of OpenRubyRMK's configuration file. 
  CONFIG_FILE = INSTALL_DIR + "config" + "OpenRubyRMK-rc.yml"
  #In this directory and it's subdirectories reside plugins. 
  PLUGINS_DIR = INSTALL_DIR + "plugins"
  #Since Ruby's Math module doesn't define INFINITY for whatever reason...
  INFINITY = 1.0/0.0
  #Negative infinity. 
  NINFINITY = -INFINITY
  
  @project_path = nil #Supresses this silly "not defined" warning when calling ::has_project?. 
  
  class << self
    
    #Initializes everything needed in order to run OpenRubyRMK. 
    #It processes the command-line switches, sets the logger up 
    #and loads the configuration file. Finally, it creates the 
    #temporary directory OpenRubyRMK extracts files into. 
    #Call this method before you start any working with OpenRubyRMK. 
    def setup
      parse_argv
      create_logger
      load_config
      create_tempdir
    end    
    
    #Returns true if either -D or -d was passed to 
    #OpenRubyRMK, or if $DEBUG is set, which is the 
    #case when -d was passed to Ruby itself. 
    def debug_mode?
      options[:debug] || $DEBUG
    end
    
    #This method executes the given code block if OpenRubyRMK 
    #is run in debug mode. When executing a debug block, it prints 
    #information about the execution time. 
    def debug
      return unless $DEBUG
      $log.debug "Executing debug code at: "
      caller.each{|call| $log.debug(call)}
      yield
    end
    
    #Convenience method that checks wheather ::project_path returns nil. 
    #If so, no project is considered selected and false is returned, true otherwise. 
    def has_project?
      !project_path.nil?
    end    
    
    #The hash this method returns contains all passed command-line 
    #switches and those not passed mapped to a default value. 
    #It's just shorthand for <tt>OpenRubyRMK::OptionHandler.options</tt>. 
    def options
      OptionHandler.options
    end
    
    #Your direct access to OpenRubyRMK's configuration file. This 
    #is a hash of form 
    #  {config_option => config_value, ...}
    #where both objects are strings. Please don't change entries 
    #you don't know about. If you want to add your own, do this 
    #directly in the configuration file.
    def config
      @config
    end
    
    #The path of the temporary directory that 
    #was created at the beginning. 
    def tempdir
      @temp_dir
    end
    
    #The directory the extracted mapsets of a project 
    #reside in. 
    def temp_mapsets_dir
      @temp_dir + "mapsets"
    end
    
    #The directory the extracted characters of a project 
    #reside in. 
    def temp_characters_dir
      @temp_dir + "characters"
    end
    
    #Deletes everything contained in the temporary directory 
    #recursively, but doesn't delete the directory itself. 
    def clear_tempdir
      @temp_dir.children.each do |filename|
        if filename.directory?
          filename.rmtree
        else
          filename.delete
        end
      end
    end
    
    #The path of the project actually edited with OpenRubyRMK. 
    #+nil+, if no project is edited (usually at startup time). 
    def project_path
      @project_path
    end
    
    #Sets the path of the project that is actually edited by OpenRubyRMK. 
    #You must call this method once, before you start working with a project. 
    def project_path=(path)
      @project_path = Pathname.new(path)
    end
    
    #The directory where a project's maps reside. 
    def project_maps_dir
      @project_path + "data" + "maps"
    end
    
    #The file describing the parent-children hierarchy of maps. 
    def project_maps_structure_file
      project_maps_dir + "structure.bin"
    end
    
    #This is the directory where a project's mapsets reside. 
    def project_mapsets_dir
      @project_path + "data" + "graphics" + "mapsets"
    end
    
    #In this directory reside a project's character graphics. 
    def project_characters_dir
      @project_path + "data" + "graphics" + "characters"
    end
    
    private
    
    #Processes the command-line options. 
    def parse_argv
      OptionHandler.parse(ARGV)
    end
    
    #Creates OpenRubyRMK's Logger. If the -d or -D option 
    #was passed to OpenRubyRMK, it will be set up to to 
    #log everything (i.e. the level is set to DEBUG) to 
    #the standard output. If -l is given without a file 
    #argument, it logs to the standard output as well, 
    #and if a file argument is given, that file will be 
    #logged into. If -l is not given at all, the logger writes 
    #to auto-rolled logfiles in the bin/logs directory which 
    #will be created if necessary. Note that the -l option 
    #doesn't affect the logging level as -d and -D do. 
    #Finally, there's the -L option which sets the logging 
    #level, starting from 0 (DEBUG) and reaching to 5 (UNKNOWN). 
    #If -L is not passed, the level is set to WARN (3). 
    #As with the -l option, -L is ignored if -d or -D was passed. 
    def create_logger
      if debug_mode?
        $log = Logger.new($stdout)  
        $log.level = Logger::DEBUG
        $stdout.sync = true
        $stderr.sync = true
      elsif options[:logfile].nil?
        $log = Logger.new(LOG_DIR + "OpenRubyRMK.log", 5, 1048576) #1 MiB
        $log.level = options[:loglevel] #returns WARN if -L is not set
      else
        $log = Logger.new(options[:logfile])
        $log.level = options[:loglevel] #returns WARN if -L is not set
      end      
      $log.datetime_format =  "%d.%m.%Y, %H:%M:%S Uhr "
    end
    
    #Loads OpenRubyRMK's main configuration file. 
    def load_config
      $log.info "Loading configuration file."
      @config = YAML.load_file(CONFIG_FILE)
    end
    
    #Creates a temporary directory where we're going to 
    #extract graphics into. 
    def create_tempdir
      @temp_dir = Pathname.new(Dir.mktmpdir("OpenRubyRMK"))
      $log.debug("Created temporary directory '#{@temp_dir}'.")
      at_exit do
        $log.debug("Removing temporary directory '#{@temp_dir}'.")
        @temp_dir.rmtree
      end
      
    end
    
  end
  
end

#Internal requires
require_relative "open_ruby_rmk/errors"
require_relative "open_ruby_rmk/map"
require_relative "open_ruby_rmk/mapset"
require_relative "open_ruby_rmk/map_field"
require_relative "open_ruby_rmk/character"
require_relative "open_ruby_rmk/option_handler"
require_relative "open_ruby_rmk/open_ruby_rmkonsole"
