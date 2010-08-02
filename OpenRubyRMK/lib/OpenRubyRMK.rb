#!/usr/bin/env ruby
#Encoding: UTF-8

=begin
This file is part of OpenRubyRMK. 

Copyright © 2010 Hanmac, Kjarrigan, Quintus

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

#Check out the Ruby version
if RUBY_VERSION < "1.9.1"
  $stderr.puts("Unsuitable Ruby version. Please use a 1.9.1 or greater Ruby.")
  exit 1
end

#Load dependendies - we don't need all the warnings displayed 
#when loading wxRuby, so silence them by unsetting $VERBOSE 
#and reassigning it later. 
v, $VERBOSE = $VERBOSE, nil
require "yaml"
require "pathname"
require "r18n-desktop"
require "wx"
$VERBOSE = v

#Set up the directory configuration so we can do relative operations without 
#harm. 

module OpenRubyRMK
  VERSION = "0.0.1-dev (1.8.10)".freeze
  
  ROOT_DIR = Pathname.new(File.expand_path(".."))
  DATA_DIR = ROOT_DIR + "data"
  LOCALE_DIR = ROOT_DIR + "locale"
  CONFIG_FILE = ROOT_DIR + "config" + "OpenRubyRMK-rc.yml"
end

#Require all the GUI files
require_relative "open_ruby_rmk/gui/application"
require_relative "open_ruby_rmk/gui/main_frame"
require_relative "open_ruby_rmk/gui/map_hierarchy"

#Now start OpenRubyRMK

app = OpenRubyRMK::GUI::Application.new
app.main_loop