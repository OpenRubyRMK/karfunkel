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

require_relative "../../lib/open_ruby_rmk/karfunkel"

begin
  server = OpenRubyRMK::Karfunkel::Karfunkel.instance(OpenRubyRMK::Karfunkel::Karfunkel::URI)
  server.start
rescue => e
  #$log.debug("Karfunkel's global exception handler was triggered!")
  #$log.fatal(e.class.name + ": " + e.message)
  #$log.fatal("Backtrace:")
  #e.backtrace.each{|trace| $log.fatal(trace)}
  
  raise
end