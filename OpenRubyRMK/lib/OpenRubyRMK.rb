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
if RUBY_VERSION != "1.9.1"
  $stderr.puts("Unsuitable Ruby version. Please use a 1.9.1 Ruby.")
  exit 1
end

#Now start OpenRubyRMK
#...since the GUI isn't wrote, just do something else. 
#Hey, it's only for testing! 

if RUBY_PLATFORM =~ /linux/
  system("xmessage", 'This is an awesome test for linux platforms!')
elsif RUBY_PLATFORM =~ /mingw|mswin/
  require "win32api"
  msgbox = Win32API.new("user32", "MessageBoxA", 'LPPI', 'I')
  msgbox.call(0, "You're now running OpenRubyRMK! ... At least a test for it.", "OpenRubyRMK", 0)
else
  raise("Unsupported platform!")
end
#Feel free to add test messsages for other platforms 
#until we are building the GUI!