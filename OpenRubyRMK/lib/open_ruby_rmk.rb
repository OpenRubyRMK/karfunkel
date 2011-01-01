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

require "bundler/setup"
require "pathname"
require "rbconfig"
require "tempfile"
require "logger"
require "nokogiri"
require "chunky_png" #Chunky bacon?!

#This is the namespace of the OpenRubyRMK library.
#Please note the word "project" always refers to games
#created with OpenRubyRMK. If we refer to OpenRubyRMK
#itself, we spell out the full name "OpenRubyRMK".
module OpenRubyRMK
  
  #The version of the OpenRubyRMK lib you're using.
  VERSION = "0.0.1-dev (22.12.10)".freeze
  
end
