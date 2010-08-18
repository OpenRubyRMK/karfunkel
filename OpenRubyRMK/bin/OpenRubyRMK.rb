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

#Load dependendies - we don't need all the warnings displayed 
#when loading wxRuby, so silence them by unsetting $VERBOSE 
#and reassigning it later. 
v, $VERBOSE = $VERBOSE, nil
require "wx"
require "stringio"
$VERBOSE = v

#Require the lib
require_relative "../lib/open_ruby_rmk"
#Require the GUI lib
require_relative "../lib/open_ruby_rmk/gui"
require_relative "../lib/open_ruby_rmk/gui/application"
require_relative "../lib/open_ruby_rmk/gui/field_renderer"
require_relative "../lib/open_ruby_rmk/gui/mapset_table_base"
require_relative "../lib/open_ruby_rmk/gui/windows/main_frame"
require_relative "../lib/open_ruby_rmk/gui/windows/map_dialog"
require_relative "../lib/open_ruby_rmk/gui/windows/mapset_window"
require_relative "../lib/open_ruby_rmk/gui/windows/console_window"
require_relative "../lib/open_ruby_rmk/gui/windows/properties_window"
require_relative "../lib/open_ruby_rmk/gui/controls/terminal"
require_relative "../lib/open_ruby_rmk/gui/controls/map_hierarchy"
require_relative "../lib/open_ruby_rmk/plugins" #Not sure -- belongs this to the GUI or the core lib?

exit if defined? Ocra #That means the script is being compiled for Windows by OCRA

#Now start OpenRubyRMK

app = OpenRubyRMK::GUI::Application.new
app.main_loop