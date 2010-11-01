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
  
  #This module encapsulates all the different directories we work with. 
  #Most likely you won't need the constants defined here, but rather 
  #directly rely on the module methods. 
  module Paths
    
    #OpenRubyRMK's root dir. This is *not* the root dir of a game 
    #created with OpenRubyRMK, but refers to OpenRubyRMK's 
    #installation directory. On Windows, it's the temporary directory 
    #created by OCRA. 
    ROOT_DIR = Pathname.new(__FILE__).dirname.parent.parent.expand_path
    #OpenRubyRMK's real installation directory. On Windows, this is the 
    #directory where OpenRubyRMK was installed to (in contrast to ROOT_DIR). 
    #On other systems, this is the same as ROOT_DIR. 
    INSTALL_DIR = ENV.has_key?("OCRA_EXECUTABLE") ? Pathname.new(ENV["OCRA_EXECUTABLE"].tr("\\", "/")).parent.parent : ROOT_DIR #OCRA_EXECUTABLE is defined for Windows *.exe files
    #Directory where GUI icons etc. are found. 
    DATA_DIR = ROOT_DIR + "data"
    #The directory where log files are created in. 
    LOG_DIR = INSTALL_DIR + "bin" + "logs"
    
    BIN_CLIENTS_DIR = INSTALL_DIR + "bin" + "clients"
    #This directory contains OpenRubyRMK's translation files. 
    LOCALE_DIR =  INSTALL_DIR + "locale"
    
    CONFIG_DIR = INSTALL_DIR + "config"
    #This is the path of OpenRubyRMK's configuration file. 
    CONFIG_FILE = INSTALL_DIR + "config" + "OpenRubyRMK-rc.yml"
    #In this directory and it's subdirectories reside plugins. 
    PLUGINS_DIR = INSTALL_DIR + "plugins"
    
    @project_path = nil #Supresses this silly "not defined" warning when calling OpenRubyRMK.has_project?. 
    
    class << self
      
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
      
      #The path of the temporary directory that 
      #was created at the beginning. 
      def tempdir
        @temp_dir
      end
      
      #This should only be called by the OpenRubyRMK.create_tempdir method. 
      #It assigns the temporary directory for further use. 
      def tempdir=(path)
        raise(RuntimeError, "Can't assign the temporary directory twice!") if defined? @tempdir
        @temp_dir = path
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
      
    end
    
  end
  
end
