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
  #Path information about the projects created are stored in their
  #respective Project objects. This module just contains information about
  #OpenRubyRMK's main directory structure.
  module Paths
    
    #If we're running on Windows, use rubyw
    windows_add = RUBY_PLATFORM =~ /mswin|mingw/ ? "w" : ""
    #Path to the Ruby executable.
    RUBY = Pathname.new(RbConfig::CONFIG["bindir"] + File::SEPARATOR + RbConfig::CONFIG["ruby_install_name"] + windows_add).to_s
    
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
    #In this directory the files for spawning internal processes are stored.
    EXTRA_PROCESSES_DIR = INSTALL_DIR + "bin" + "extra_processes"
    #This directory contains OpenRubyRMK's translation files.
    LOCALE_DIR =  INSTALL_DIR + "locale"
    
    CONFIG_DIR = INSTALL_DIR + "config"
    #This is the path of OpenRubyRMK's configuration file.
    CONFIG_FILE = INSTALL_DIR + "config" + "OpenRubyRMK-rc.yml"
    #In this directory and it's subdirectories reside plugins.
    PLUGINS_DIR = INSTALL_DIR + "plugins"
    #The file that contains the version of OpenRubyRMK
    VERSION_FILE = ROOT_DIR + "VERSION.txt"
    
  end
  
end
