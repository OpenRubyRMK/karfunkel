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
  
  module Karfunkel
    
    module ProjectManagement
      
      #A Mapset is directly tied to a file containing every field you can use
      #for map creation.
      class Mapset
        
        #The edge size of a single field, in pixels.
        FIELD_EDGE = 32
        
        #The project this mapset belongs to.
        attr_reader :project
        #The absolute name of the file the image data is read from.
        attr_reader :filename
        #Number of rows in a mapset, where a row is FIELD_EDGE pixels wide.
        attr_reader :rows
        #Number of columns in a mapset, where a column is FIELD_EDGE pixels wide.
        attr_reader :columns
        #The image of the whole mapset. A ChunkyPNG::Image object.
        attr_reader :image
        
        #Loads a mapset by reading from an image file. Just pass in the file's basename,
        #it will be prepended by the project's mapset search path automatically.
        def self.load(project, filename)
          obj = allocate
          obj.instance_eval do
            @project = project
            @filename = @project.paths.temp_mapsets_dir + filename.match(/\..*?$/).pre_match + filename #Each map has it's own directory
            raise(Errno::ENOENT, "Mapset not found: #{filename}!") unless @filename.file?
            @image = ChunkyPNG::Image.from_file(@filename.to_s)
            split_into_tiles
            @columns = @data.size
            @rows = @data.transpose.size
          end
          obj
        end
        
        #Grabs the ChunkyPNG::Image at the specified position.
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
          raise(Errors::InvalidMapsetError, "Invalid mapset dimensions #{img.width} x #{img.height}!") unless @image.width % FIELD_EDGE == 0 and @image.height % FIELD_EDGE == 0
          cols = @image.width / FIELD_EDGE
          rows = @image.height / FIELD_EDGE
          
          @data = Array.new(cols){Array.new(rows)}
          0.upto(cols - 1) do |col|
            0.upto(rows - 1) do |field|
              subimg = @image.crop(col * FIELD_EDGE, field * FIELD_EDGE, FIELD_EDGE, FIELD_EDGE)
              @data[col][field] = subimg
            end
          end
        end
        
      end
      
    end
    
  end
  
end
