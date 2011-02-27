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

#Check out the Ruby version
if RUBY_VERSION < "1.9.1"
  $stderr.puts("Unsuitable Ruby version. Use 1.9.1 or greater.")
  exit 1
end

#Require Karfunkel's dependencies
require "bundler/setup"
require "pathname"
require "rbconfig"
require "socket"
require "tempfile"
require "logger"
require "zlib"
require "nokogiri"
require "chunky_png" #Chunky bacon?!
require "eventmachine"
require "archive/tar/minitar"

#Now require Karfunkel himself
require_relative "../../lib/open_ruby_rmk/karfunkel/server_management/karfunkel"

EventMachine.run do
  OpenRubyRMK::Karfunkel::SM::Karfunkel.start
end
