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
        
        #The absolute name of the file the image data is read from.
        attr_reader :filename
        #Number of rows in a mapset, where a row is FIELD_EDGE pixels wide.
        
        #Loads a mapset by reading from an image file.
        #==Parameter
        #[filename] The path to the mapset file.
        #==Return value
        #The loaded mapset.
        #==Example
        #  Mapset.load("/home/freak/myproject/mapsets/mymapset.png")
        def self.load(filename)
          obj = allocate
          obj.instance_eval do
            @filename = filename #Each map has it's own directory
            raise(Errno::ENOENT, "Mapset not found: #{filename}!") unless @filename.file?
          end
          obj
        end
        
        #true if +self+ and +other+ refer to the same filename.
        def ==(other)
          @filename == other.filename
        end
        
      end
      
    end
    
  end
  
end
