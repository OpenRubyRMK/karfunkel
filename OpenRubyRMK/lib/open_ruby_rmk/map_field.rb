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
  
  #A single field on the map. Every field has an image and knows about it's location. 
  #If the image on a field isn't set, it points to MapField.null_image, which is just a 
  #transparent image that not even gets saved into the map files (it's represented with 
  #+nil+ in those). 
  class MapField
    
    #The Wx::Image that gets displayed. 
    attr_reader :image
    #A hash of characters. 
    attr_reader :characters
    #The field's X coordinate on the map. 
    attr_reader :x
    #The field's Y coordinate on the map. 
    attr_reader :y
    #The field's Z coordinate on the map. 
    attr_reader :z
    #The field's image's X coordinate on the mapset. 
    attr_reader :mapset_x
    #The field's image's Y coordinate on the mapset. 
    attr_reader :mapset_y
    
    #Returns a 32x32 pixels graphic (a Wx::Image object). This is used where 
    #no field image has been set. 
    def self.null_image
      @null_image ||= Wx::Image.new(OpenRubyRMK::Paths::DATA_DIR.join("transparent32x32.png").to_s, Wx::BITMAP_TYPE_PNG)
    end
    
    #Creates a new Field. Pass in the field's X, Y and Z coordinates on 
    #the map and the coordinates of the image on the mapset you want to 
    #use. 
    def initialize(map, x, y, z, mapset_x = nil, mapset_y = nil)
      @map = map
      @x, @y, @z = x, y, z
      @mapset_x, @mapset_y = mapset_x, mapset_y
      if @mapset_x and @mapset_y
        @image = @map.mapset[@mapset_x, @mapset_y]
      else
        @image = self.class.null_image
      end
      @characters = []
    end
    
    #Human-readable description of form 
    #  <OpenRubyRMK::MapField on map ID <map_id> at (x|y|z)>
    #. 
    def inspect
      "<#{self.class} on map ID #{@map.id} at (#{@x}|#{@y}|#{@z})>"
    end
    
    #Sets this field's image to that one at the given coordinate on the mapset. 
    def reassign_image(x, y)
      @image = @map.mapset[x, y]
      @mapset_x = x
      @mapset_y = y
    end
    
    #true if this field has an associated image that can be displayed. 
    #This doesn't check for any Characters being on this field. 
    def has_image?
      @image != self.class.null_image
    end
    
    #Unsets this field's image by setting it to the 
    #null image. 
    def clear_image!
      @mapset_x = @mapset_y = nil
      @image = self.class.null_image
    end
    
    #Unsets the image associated with this field and deletes any 
    #characters that are on it. 
    def clear!
      clear_image!
      @characters.clear
      nil
    end
    
    #true if this field has neither an own image nor any characters 
    #placed on it. 
    def clear?
      !has_image? and @characters.empty?
    end
    
    #This objects get rendered by a Wx::GridCellStringRenderer (look into 
    #to documentation of my monkeypatched Wx::Image class to know why) 
    #and has therefore to pretend it was empty string. 
    def to_str
      ""
    end
    
  end
  
end