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
  
  #A single field on the map. 
  class Field
    
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
    
    #Loads a Field object. This method is a bit superfluous at the moment, 
    #although it's called by Map#load... 
    #Same arguments as for ::new, except ary, which 
    #is 
    #  [mapset_x, mapset_y, characters_hash]
    #...
    def self.load(x, y, z, mapset, ary)
      obj = allocate
      obj.instance_eval do
        @x, @y, @z = x, y, z
        @mapset_x, @mapset_y = ary[0], ary[1]
        @mapset = mapset
        @image = @mapset[@mapset_x, @mapset_y]
        @characters = {} #TODO
      end
      obj
    end
    
    #Creates a new Field. Pass in the field's X, Y and Z coordinates on 
    #the map and the coordinates of the image on the mapset you want to 
    #use. 
    def initialize(mapset, x, y, z, mapset_x, mapset_y)
      @mapset = mapset
      @x, @y, @z = x, y, z
      @image = @mapset[mapset_x, mapset_y]
      @characters = []
    end
    
  end
  
end