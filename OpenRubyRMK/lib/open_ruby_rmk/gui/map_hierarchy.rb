#!/usr/bin/env ruby
#Encoding: UTF-8

=begin
This file is part of OpenRubyRMK. 

Copyright © 2010 Hanmac, Kjarrigan, Quintus

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
  
  module GUI
    
    #This class represents the map hierarchy. It's independant on how the Map 
    #class will be defined. 
    class MapHierarchy < Wx::TreeCtrl
      include Wx
      
      #Creates a new MapHierarchy object, where +root_name+ is the string 
      #that will be displayed next to the root node. The +maps+ argument is a 
      #multidimensional hash of the following form: 
      #  {
      #    "name1" => aMap, #This is a normal map. 
      #    "name2" => {:map => aSecondMap, :hsh => {<same_format_again>}} #This map has got submaps. 
      #  }
      #where "name1" and "name2" are the strings that will be displayed next to the node containing 
      #the given map. Note that this class doesn't actually do anything with the maps you 
      #assign, it just remembers them. You should use the <tt>evt_tree_sel_changed(id)</tt> event handler and 
      #call TreeEvent#item on the event, from whose return value in turn you can retrieve the Map object 
      #from the MapHierarchy instance via #get_item_data. 
      def initialize(parent, root_name, maps = {})
        super(parent)
        
        i = ImageList.new(24, 24)
        i.add(Bitmap.new(DATA_DIR.join("ruby16x16.png").to_s, BITMAP_TYPE_PNG))
        i.add(Bitmap.new(DATA_DIR.join("map16x16.png").to_s, BITMAP_TYPE_PNG))
        self.image_list = i
        
        @root = add_root(root_name, 0)
        
        return if maps.empty?
        buildup_tree(maps)
      end
      
      #Recreates the tree view completely. Pass in the root node's string 
      #and the hash containing the maps to display. See MapHierarchy.new for 
      #a description of the hash's format. 
      def recreate_tree!(root_name, maps)
        delete_all_items
        @root = add_root(root_name, 0)
        buildup_tree(maps)
      end
      
      private
      
      #Recursively iterates over the given hash and appends the maps 
      #to the tree view. See MapHierarchy.new for a description of 
      #the hash's format. 
      def buildup_tree(hsh, parent = @root)
        hsh.each_pair do |name, map|
          if map.kind_of? Hash
            par = append_item(parent, name, 1, -1, map[:map])
            buildup_tree(map[:hsh], par)
          else
            append_item(parent, name, 1, -1, map)
          end
        end
      end
      
    end
    
  end
  
end