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
  
  #A Mapset is directly tied to a file containing every field you can use 
  #for map creation. 
  #
  #TODO: This class is dependant of wxRuby (for the image manipulation), although 
  #it doesn't reside in the GUI namespace. This class actually *isn't* GUI-related, but 
  #since wxRuby supplies the image manipulation methods needed for this class (image resizing, 
  #cutting, etc.) and I didn't find a small graphics library that could be used as an extra 
  #dependency of OpenRubyRMK (RMagick is way to big and complicated on Windows)... 
  #Proposals?
  class Mapset
    
    #The edge size of a single field, in pixels. 
    FIELD_EDGE = 32
    
    #The name of the file the image data is read from. 
    attr_reader :filename
    #Number of rows in a mapset, where a row is FIELD_EDGE pixels wide. 
    attr_reader :rows
    #Number of columns in a mapset, where a column is FIELD_EDGE pixels wide. 
    attr_reader :columns
    
    def self.extract_archives
      Errors::NoProjectError.throw! unless OpenRubyRMK.has_project?
      Dir.glob(OpenRubyRMK::Paths.project_mapsets_dir.join("**", "*.tgz").to_s).map{|f| Pathname.new(f)}.each do |filename|
        $log.debug("Extracting map '#{filename}'")
        temp_filename = OpenRubyRMK::Paths.temp_mapsets_dir + filename.relative_path_from(OpenRubyRMK::Paths.project_mapsets_dir)
        gz = Zlib::GzipReader.open(filename)
        Archive::Tar::Minitar.unpack(gz, temp_filename.parent) ##unpack automatically closes the file
      end
    end
    
    #Loads a mapset by reading from an image file. Just pass in the file's basename, 
    #it will be prepended by the current project's mapset search path automatically. 
    def self.load(filename)
      obj = allocate
      obj.instance_eval do
        @filename = OpenRubyRMK::Paths.temp_mapsets_dir + filename.match(/\..*?$/).pre_match + filename #Each map has it's own directory
        raise(Errno::ENOENT, "Mapset not found: #{filename}!") unless @filename.file?
        split_into_tiles
        @columns = @data.size
        @rows = @data.transpose.size
      end
      obj
    end
    
    #Grabs the Wx::Image at the specified position. 
    def [](x, y)
      @data[x][y]
    end
    
    #true if +self+ and +other+ refer to the same filename. 
    def ==(other)
      @filename == other.filename
    end
    
    private
    
    #Splits a mapset file into smaller images of size FIELD_EDGE x FIELD_EDGE and assigns 
    #the subimages to the @data instance variable. 
    def split_into_tiles
      img = Wx::Image.new(@filename.to_s)
      raise(Errors::InvalidMapsetError, "Invalid mapset dimensions #{img.width} x #{img.height}!") unless img.width % FIELD_EDGE == 0 and img.height % FIELD_EDGE == 0
      cols = img.width / FIELD_EDGE
      rows = img.height / FIELD_EDGE
      
      @data = Array.new(cols){Array.new(rows)}
      0.upto(cols - 1) do |col|
        0.upto(rows - 1) do |field|
          subimg = img.sub_image(Wx::Rect.new(col * FIELD_EDGE, field * FIELD_EDGE, FIELD_EDGE, FIELD_EDGE))
          @data[col][field] = subimg
        end
      end
    end
    
  end
  
end