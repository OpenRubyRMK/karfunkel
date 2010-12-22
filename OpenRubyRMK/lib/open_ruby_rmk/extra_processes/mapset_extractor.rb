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
require "archive/tar/minitar"
require "zlib"

module OpenRubyRMK
  
  class MapsetExtractor
    
    def initialize(mapsets_dir, temp_mapsets_dir)
      @mapsets_dir = Pathname.new(mapsets_dir)
      @temp_mapsets_dir = Pathname.new(temp_mapsets_dir)
    end
    
    def extract
      files = Dir.glob(@mapsets_dir.join("**", "*.tgz").to_s).map{|f| Pathname.new(f)}
      num = files.length
      files.each_with_index do |filename, index|
        temp_filename = @temp_mapsets_dir + filename.relative_path_from(@mapsets_dir)
        gz = Zlib::GzipReader.open(filename)
        Archive::Tar::Minitar.unpack(gz, temp_filename.parent) ##unpack automatically closes the file
        #Output the current load status in percent.
        puts((index + 1 / num).to_f * 100)
      end
    end
  
  end
  
end
