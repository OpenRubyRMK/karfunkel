# -*- coding: utf-8 -*-
#
# This file is part of OpenRubyRMK.
# 
# Copyright © 2010 OpenRubyRMK Team
# 
# OpenRubyRMK is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
# 
# OpenRubyRMK is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with OpenRubyRMK.  If not, see <http://www.gnu.org/licenses/>.

module OpenRubyRMK
  
  class Karfunkel
  
    #This module encapsulates all the different directories we work with.
    #Path information about the projects created are stored in their
    #respective Project objects. This module just contains information about
    #Karfunkel's main directory structure.
    module Paths

      #If we're running on Windows, use rubyw
      windows_add = RUBY_PLATFORM =~ /mswin|mingw/ ? "w" : ""
      #Path to the Ruby executable.
      RUBY = Pathname.new(RbConfig::CONFIG["bindir"] + File::SEPARATOR + RbConfig::CONFIG["ruby_install_name"] + windows_add).to_s
      
      #Karfunkel's root dir. This is *not* the root dir of a game
      #created with OpenRubyRMK, but refers to Karfunkel's
      #installation directory. On Windows, it's the temporary directory
      #created by OCRA.
      ROOT_DIR = Pathname.new(__FILE__).dirname.parent.parent.parent.expand_path
      #Karfunkel's real installation directory. On Windows, this is the
      #directory where Karfunkel was installed to (in contrast to ROOT_DIR).
      #On other systems, this is the same as ROOT_DIR.
      INSTALL_DIR = ENV.has_key?("OCRA_EXECUTABLE") ? Pathname.new(ENV["OCRA_EXECUTABLE"].tr("\\", "/")).parent.parent : ROOT_DIR #OCRA_EXECUTABLE is defined for Windows *.exe files
      #The directory where log files are created in.
      LOG_DIR = INSTALL_DIR + "bin" + "logs"
      #The directory where Karfunkel's global configuration file resides in.
      CONFIG_DIR = INSTALL_DIR + "config"
      #Here are the executable files to be found.
      BIN_DIR = INSTALL_DIR + "bin"
      #Where temporary stuff (like the PID file) is stored.
      TMP_DIR = INSTALL_DIR + "tmp"
      #This is the path of Karfunkel's configuration file.
      CONFIG_FILE = CONFIG_DIR + "main.conf"
      #Where to find the plugin list.
      PLUGINS_FILE = CONFIG_DIR + "plugins.conf"
      #Directory containing the basic structure for new projects.
      SKELETON_DIR = CONFIG_DIR + "skeleton"
      #From this directory all files are loaded automatically. It’s
      #inteded for plugins.
      PLUGIN_DIR = INSTALL_DIR + "plugins"
      #The file that contains the version of OpenRubyRMK (should be the
      #same version for the server and the clients).
      VERSION_FILE = ROOT_DIR + "VERSION"
      
    end
    
  end
  
end
