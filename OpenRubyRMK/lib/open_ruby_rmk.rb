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
require "pathname"
require "r18n-desktop"
require "pp"

#This is the namespace of the OpenRubyRMK library. 
#Please note the word "project" always refers to games 
#created with OpenRubyRMK. If we refer to OpenRubyRMK 
#itself, we spell out the full name "OpenRubyRMK". 
module OpenRubyRMK
  
  #The version of the OpenRubyRMK lib you're using. 
  VERSION = "0.0.1-dev (18.8.10)".freeze
  
  #OpenRubyRMK's root dir. This is *not* the root dir of a game 
  #created with OpenRubyRMK, but refers to OpenRubyRMK's 
  #installation directory. 
  ROOT_DIR = Pathname.new(__FILE__).dirname.parent.expand_path
  #Directory where GUI icons etc. are found. 
  DATA_DIR = ROOT_DIR + "data"
  #This directory contains OpenRubyRMK's translation files. 
  LOCALE_DIR = ENV.has_key?("OCRA_EXECUTABLE") ? Pathname.new(ENV["OCRA_EXECUTABLE"].tr("\\", "/")).parent.parent + "locale" : ROOT_DIR + "locale" #OCRA_EXECUTABLE is defined for Windows *.exe files
  #This is the path of OpenRubyRMK's configuration file. 
  CONFIG_FILE = ENV.has_key?("OCRA_EXECUTABLE") ? Pathname.new(ENV["OCRA_EXECUTABLE"].tr("\\", "/")).parent.parent + "config" + "OpenRubyRMK-rc.yml" : ROOT_DIR + "config" + "OpenRubyRMK-rc.yml"
  #In this directory and it's subdirectories reside plugins. 
  PLUGINS_DIR = ENV.has_key?("OCRA_EXECUTABLE") ? Pathname.new(ENV["OCRA_EXECUTABLE"].tr("\\", "/")).parent.parent + "plugins" : ROOT_DIR + "plugins"
  #Since Ruby's Math module doesn't define INFINITY for whatever reason...
  INFINITY = 1.0/0.0
  #Negative infinity. 
  NINFINITY = -INFINITY
  
  @project_path = nil #Supresses this silly "not defined" warning when calling ::has_project?. 
  
  class << self
    
    #Convenience method that checks wheather ::project_path returns nil. 
    #If so, no project is considered selected and false is returned, true otherwise. 
    def has_project?
      !project_path.nil?
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
    
  end
end

#Internal requires
require_relative "open_ruby_rmk/errors"
require_relative "open_ruby_rmk/map"
require_relative "open_ruby_rmk/mapset"
require_relative "open_ruby_rmk/field"
require_relative "open_ruby_rmk/open_ruby_rmkonsole"