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

#Returns a truth value if OCRA is compressing 
#this script at the moment. 
def compressing?
  defined? Ocra
end

require "rbconfig"
require "pathname"
if compressing?
  #These requires aren't needed for the startup script, 
  #but have to be included in the OCRA-compressed Windows 
  #executable. 
  v, $VERBOSE = $VERBOSE, nil #Suppresses tons of warnings we don't care about
  require "bundler/setup"
  require "wx"
  require "drb"
  require "timeout"
  require "irb"
  $VERBOSE = v #Ensure warnings shown hereafter get visible
  exit
end

#If we're running on Windows, use rubyw
windows_add = "w" if RUBY_PLATFORM =~ /mswin|mingw/
#Get the name of the Ruby executable.
ruby = Pathname.new(RbConfig::CONFIG["bindir"] + File::SEPARATOR + RbConfig::CONFIG["ruby_install_name"] + windows_add)
#Get the name of the directory this script resides in
this_dir = Pathname.new(__FILE__).dirname.expand_path
#Get the server script's name
karfunkel = this_dir.join("server","karfunkel.rb")
#Get the main client's names
clients = [this_dir + "clients" + "gui_client.rb"]

#Spawn clients
clients.each{|pathname| spawn(ruby.to_s, pathname.to_s)}
#Start the server
exec(ruby.to_s, karfunkel.to_s)