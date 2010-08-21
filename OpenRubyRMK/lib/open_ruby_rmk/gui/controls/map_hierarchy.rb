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
  
  module GUI
    
    module Controls
      
      #This class represents the map hierarchy. It's independant on how the Map 
      #class will be defined. 
      class MapHierarchy < Wx::TreeCtrl
        include Wx
        
        #Creates a new MapHierarchy object, where +root_name+ is the string 
        #that will be displayed next to the root node. The +maps+ argument is a 
        #multidimensional hash of the following form: 
        #  {
        #    id1 => {:map => aMap, :children => {}}, #This is a normal map. 
        #    id2 => {:map => aSecondMap, :children => {<same_format_again>}} #This map has got submaps. 
        #  }
        #where id1 and id2 are a map's unique identifier. The actual string that is displayed next
        #to the map icon is determined from <tt>aMap.name</tt>. 
        #Note that this class doesn't actually do anything with the maps you assign (beside using the name), 
        #it just remembers them. You should use the <tt>evt_tree_sel_changed(id)</tt> event handler and 
        #call TreeEvent#item on the event, from whose return value in turn you can retrieve the Map object 
        #from the MapHierarchy instance via #get_item_data. 
        def initialize(parent, root_name, maps = {})
          super(parent)
          
          i = ImageList.new(16, 16)
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
          expand(@root) #Looks better
        end
        
        #Returns the currently selected map or +nil+ if none or the root 
        #node is selected. 
        def selected_map
          get_item_data(get_selection)
        end
        
        #Iterates through all maps and refreshes the tree view's names 
        #based on the +name+ values each map object returns. 
        def update_map_names
          each do |id|
            data = get_item_data(id)
            next if data.nil? #Root item
            set_item_text(id, data.name)
          end
        end
        
        private
        
        #Recursively iterates over the given hash and appends the maps 
        #to the tree view. See MapHierarchy.new for a description of 
        #the hash's format. 
        def buildup_tree(hsh, parent = @root)
          hsh.each_pair do |id, hsh2|
            if !hsh2[:children].empty?
              par = append_item(parent, hsh2[:map].name, 1, -1, hsh2[:map])
              buildup_tree(hsh2[:children], par)
            else
              append_item(parent, hsh2[:map].name, 1, -1, hsh2[:map])
            end
          end
        end
        
      end #MapHierarchy
      
    end #Controls
    
  end #GUI
  
end #OpenRubyRMK