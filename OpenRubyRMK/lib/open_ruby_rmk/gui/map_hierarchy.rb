#!/usr/bin/env ruby
#Encoding: UTF-8

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
        i.add(Bitmap.new(DATA_DIR.join("ruby24x24.png").to_s, BITMAP_TYPE_PNG))
        i.add(Bitmap.new(DATA_DIR.join("file24x24.png").to_s, BITMAP_TYPE_PNG))
        self.image_list = i
        
        @root = add_root(root_name, 0)
        
        return if maps.empty?
        buildup_tree(maps)
      end
      
      #Recreates the tree view completely. Pass in the rood node's string 
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