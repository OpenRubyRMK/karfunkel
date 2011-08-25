# This file is part of OpenRubyRMK.
# 
# Copyright © 2011 OpenRubyRMK Team
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

#Executes 7-Zip with the given arguments. For example, if you want to
#extract an archive, use
#  z7 "x", "the_archive.7z"
def z7(*args)
  z7_cmd = nil
  begin
    `7z --help` #Backticks since we don't want to emit output, but an error on not-found
    z7_cmd = "7z"
  rescue Errno::ENOENT
    `7za --help` #Raises Errno::ENOENT as well if not found
    z7_cmd = "7za"
  end
  
  qsh "#{z7_cmd} #{args.map{|arg| "'#{arg}'"}.join(' ')}"
end

#Executes the +make+ command, passing it all given arguments. Too
#execute a "make install", you therefore may do
#  make :install
#(All args are converted to strings).
def make(*args)
  cmd = MAKE_JOBS > 1 ? "make -j#{MAKE_JOBS}" : "make"
  args.each{|arg| cmd << " '#{arg}'"}
  sh cmd
end

#Downloads the file at +url+ and places it in the current directory.
#Does nothing if that file already exists.
def download(url)
  file = Pathname.new(File.basename(url))
  print "Downloading #{file}... "
  if file.file?
    puts "Not needed."
  else
    open(url, "rb") do |page|
      file.open("wb") do |f|
        byte = nil
        f.putc(byte) while byte = page.getbyte
      end
    end
    puts "Done."
  end
end