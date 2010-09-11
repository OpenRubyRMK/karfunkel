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
  
  class Character
    
    attr_accessor :code
    attr_reader :graphic_filename
    attr_reader :x
    attr_reader :y
    
    def self.extract_archives
      Errors::NoProjectError.throw! unless OpenRubyRMK.has_project?
      
      Dir.glob(OpenRubyRMK::Paths.project_characters_dir.join("**", "*.tgz").to_s).map{|f| Pathname.new(f)}.each do |filename|
        $log.debug("Extracting character '#{filename}'")
        temp_filename = OpenRubyRMK::Paths.temp_characters_dir + filename.relative_path_from(OpenRubyRMK::Paths.project_characters_dir)
        gz = Zlib::GzipReader.open(filename)
        Archive::Tar::Minitar.unpack(gz, temp_filename.parent) ##unpack automatically closes the file
      end
      
    end
    
    def initialize(x, y, graphic_filename)
      @x, @y = x, y
      @graphic_filename = Pathname.new(graphic_filename)
      @code = ""
    end
    
  end
  
end