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
        
    #A single field on the map. Every field has an image and knows about it's location.
    #If the image on a field isn't set, it points to MapField.null_image, which is just a
    #transparent image that not even gets saved into the map files (it's represented with
    #+nil+ in those).
    #Note that the image isn't an actual attribute of the MapField. You can get it by
    #calling #image, which in turn calls out to the map's mapset and grabs the image
    #from there making it impossible to have the field point to an invalid image.
    class MapField
      
      #A 32x32 pixels graphic that is nothing but empty.
      #It is used where no image has been set for a field.
      NULL_IMAGE = ChunkyPNG::Image.new(32, 32, ChunkyPNG::Color::TRANSPARENT)
      
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
      
      #Creates a new Field. Pass in the field's X, Y and Z coordinates on
      #the map and the coordinates of the image on the mapset you want to
      #use.
      def initialize(map, x, y, z, mapset_x = nil, mapset_y = nil)
        @map = map
        @x, @y, @z = x, y, z
        @mapset_x, @mapset_y = mapset_x, mapset_y
        @characters = []
      end
      
      #Human-readable description of form
      #  <OpenRubyRMK::MapField on map ID <map_id> at (x|y|z)>
      #.
      def inspect
        "#<#{self.class} on map ID #{@map.id} at (#{@x}|#{@y}|#{@z})>"
      end
      
      #Grabs this field's image from the associated map's mapset and
      #returns it. Returns MapField.null_image if no mapset image is
      #set for this field. Equivalent to
      #  my_map_field.map.mapset[my_map_field.mapset_x, my_map_field.mapset_y]
      #(when an image is set). Should return a ChunkyPNG::Canvas object.
      def image
        return NULL_IMAGE if @mapset_x.nil? and @mapset_y.nil?
        @map.mapset[@mapset_x, @mapset_y]
      end
      
      #Sets this field's image to that one at the given coordinate on the mapset.
      def reassign_image(x, y)
        @mapset_x = x
        @mapset_y = y
      end
      
      #true if this field has an associated image that can be displayed.
      #This doesn't check for any Characters being on this field.
      def has_image?
        !@mapset_x.nil? or !@mapset_y.nil?
      end
      
      #Unsets this field's image by setting it to the
      #null image.
      def clear_image!
        @mapset_x = @mapset_y = nil
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
      
    end
    
  end
  
end