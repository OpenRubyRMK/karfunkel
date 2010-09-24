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
  
  #This class represents a map for the OpenRubyRMK. It has nothing to 
  #do with the Map class used inside the created games, beside the fact 
  #that both use the same file format. 
  #
  #The format of the map files is as follows: 
  #They're binary files serialized with Ruby's +Marshal+ module. Inside 
  #is a hash of this form stored: 
  #  {
  #    :name => "the name of the map", 
  #    :mapset => "name of the mapset", 
  #    :table => a_4dimensional_array, 
  #    :parent => the_id_of_the_parent_map_or_zero
  #  }
  #where the 4-dimensional array is simply the description of the three-dimensional 
  #map table (X, Y and Z coordinates) plus the information of the map field that 
  #resides at that position in form of an array. This array has this form: 
  #  [mapset_x, mapset_y, events_hsh]
  #If no field was specified for that position, no array exists but rather a +nil+ object. 
  #TODO: Describe the events hash!
  #
  #You may noticed that the ID of the map isn't contained in the serialized hash. 
  #That's because it is simply determined from the file's name, which should be 
  #like this: 
  #  <id_of_map>.bin
  #For instance: 
  #  3.bin
  #For the map with ID 3. 
  #
  #The map's hierarchy is described in the +structure.bin+ file. It a marshaled hash 
  #of this form: 
  #  {parent_id => {<hash_format>}}
  #It just describes how the map's parent-and-children-relationship gets resolved
  #and has no deep meaning besides making life easier (look at the code 
  #that loads the maps!). If there was a nice way to get the relationship resolved, I'd 
  #go it, especially because a Map object already knows about it's parent and children IDs. 
  class Map
    include Wx
    
    #The unique ID of a map. Cannot be changed. 
    attr_reader :id
    #The parent map as a Map object or nil if there is no parent. 
    attr_reader :parent
    #An array of all children maps in form of their IDs. 
    attr_reader :children_ids
    #The mapset used to display this map. 
    attr_accessor :mapset
    
    ##
    # :attr_acessor: name
    #The name of this map. If no name is set or it is empty, 
    #a stringified version of it's ID will be returned. 
    
    ##
    # :attr_accessor: width
    #The map's width in fields. 
    
    ##
    # :attr_accessor: height
    #The map's height in fields. 
    
    ##
    # :attr_accessor: depth
    #The map's depth. Indicates how many elements may 
    #reside above each other. 
    
    @maps = []
    
    #Returns the next available map ID. 
    def self.next_free_id
      ids = @maps.map(&:id)
      1.upto(INFINITY) do |n|
        break(n) unless ids.include?(n)
      end
    end
    
    #A list of all map IDs that are currently in use. 
    def self.used_ids
      @maps.map(&:id)
    end
    
    #An array containg all maps that have been created or loaded. 
    def self.maps
      @maps
    end
    
    #true if the given ID is used by some map. 
    def self.id_in_use?(id)
      used_ids.include?(id)
    end
    
    #Loads a map object from a file. The filename is detected by 
    #using OpenRubyRMK.project_maps_dir and the given ID. Raises an ArgumentError 
    #if no file is found. 
    #See this class's documentation for a description of the file format. 
    def self.load(id)
      filename = Pathname.new(OpenRubyRMK::Paths.project_maps_dir + "#{id}.bin")
      raise(ArgumentError, "Map not found: #{id}!") unless filename.file?
      hsh = filename.open("rb"){|f| Marshal.load(f)}
      id = filename.basename.to_s.to_i #Filenames are of form "3.bin" and #to_i stops at the ".". 
      
      obj = allocate
      obj.instance_eval do
        @id = id
        @name = hsh[:name]
        @mapset = Mapset.load(hsh[:mapset])
        @table = []
        hsh[:table].each_with_index do |col, i_col|
          @table[i_col] = []
          col.each_with_index do |depth_row, i_drow|
            @table[i_col][i_drow] = Array.new(depth_row.size)
            depth_row.each_with_index do |field_ary, i_field|
              if field_ary
                @table[i_col][i_drow][i_field] = MapField.new(self, i_col, i_drow, i_field, field_ary[0], field_ary[1])
              else
                @table[i_col][i_drow][i_field] = MapField.new(self, i_col, i_drow, i_field)
              end #TODO: Change the saved maps to have a [nil, nil, {}] array instead of plain nil for nonassigned fields!
              #TODO: Assign characters!
            end
          end
        end
        
        @parent = self.class.from_id(hsh[:parent])
        @parent.children_ids << @id unless @parent.nil? #Map.from_id returns nil if there's no parent
        @children_ids = []
        
      end
      @maps << obj
      obj
    end
    
    #Deletes the map with the given ID from the list of remembered maps, 
    #plus all children's IDs (recursively, so a children's children etc. also 
    #get removed). 
    #After a call to this method you shouldn't use any map object with this 
    #ID or a child ID anymore. 
    #Returns the deleted map's ID which can now be used as an available ID. 
    def self.delete(id)
      #Recursively delete all children maps
      @maps.children_ids.each do |child_id|
        delete(child_id)
      end
      #Delete this map and remove it's file
      @maps.delete_if{|map| map.id == id}
      OpenRubyRMK::Paths.project_maps_dir.join("#{id}.bin").delete rescue nil #If the file doesn't exist it can't be deleted
      id
    end
    
    #Reconstructs a map object by it's ID. Note that this ID isn't the 
    #map's object ID, but an internal ID used to uniquely identify a map. 
    #In contrast to the object ID, it persists across program sessions. 
    #Within a single session, you'll get the absolute same object back, 
    #that is, this equals true: 
    #  map = Map.new(112, ...)
    #  map2 = Map.from_id(112)
    #  map.equal?(map2)
    #That's possible since the Map class automatically remembers all 
    #created Map objects. If you want to "free" an ID, you have to explicitely 
    #delete a map by calling it's #delete! method or calling Map.delete which 
    #does the same, it just takes an ID instead of a Map object. 
    def self.from_id(id)
      return nil if id == 0 #No parent
      m = @maps.find{|map| map.id == id}
      raise(ArgumentError, "A map with ID #{id} doesn't exist!") if m.nil?
      m
    end
    
    #Creates a new Map object. Pass in the map's ID, name, initial dimensions 
    #and, if you want to create a child map, the parent map's ID (pass 0 for no parent). 
    #
    #This method remembers the maps you create in a class instance variable @maps, 
    #allowing you to reconstruct a map object just by it's ID without struggling around 
    #with ObjectSpace. 
    def initialize(id, name, mapset, width, height, depth, parent = 0) #0 is no valid map ID, i.e. it's the root element
      raise(ArgumentError, "Parent ID #{parent} doesn't exist!") if parent.nonzero? and !self.class.id_in_use?(parent)
      raise(ArgumentError, "The ID #{id} is already in use!") if self.class.id_in_use?(id)
      @id = id
      @name = name.to_str
      @mapset = mapset
      @table = Array.new(width){|x| Array.new(height){|y| Array.new(depth){|z| MapField.new(self, x, y, z)}}} #Initialize with empty fields
      @parent = self.class.from_id(parent)
      @parent.children_ids << @id unless @parent.nil? #Map.from_id returns nil if there's no parent
      @children_ids = []
      #Remember the map
      self.class.maps << self
    end
    
    #true if this map has a parent map. 
    def has_parent?
      !@parent.nil?
    end
    
    #true if this map hasn't a parent map. 
    def is_toplevel?
      @parent.nil?
    end
    
    #See accessor. 
    def width # :nodoc:
      @table.size
    end
    
    #See accessor.
    def height # :nodoc:
      @table[0].size
    end
    
    #See accessor. 
    def depth # :nodoc:
      @table[0][0].size
    end
    
    #See accessor. 
    def width=(val) # :nodoc:
      #Handle smaller and equal widths
      @table = @table[0...val] #excusive, b/c index is 0-based
      #If the map is enlarged, we need to append extra columns
      @table.size.upto(val - 1){@table << Array.new(height){Array.new(depth)}} #-1, b/c index is 0-based
    end
    
    #See accessor. 
    def height=(val) # :nodoc:
      @table.map! do |col|
        #Handle smaller and equal heights
        col = col[0...val] #excusive, b/c index is 0-based
        #Handle greater heights
        col.size.upto(val - 1){col << Array.new(depth)} #-1, b/c index is 0-based
        col
      end
    end
    
    #See accessor. 
    def depth=(val) # :nodoc:
      @table.each do |col|
        col.map! do |depth_row|
          #Handle smaller and equal dephts
          depth_row = depth_row[0...val] #excusive, b/c index is 0-based
          #Handle greater depths
          depth_row.size.upto(val - 1){depth_row << nil} #-1, b/c index is 0-based
          depth_row
        end
      end
    end
    
    #Returns an array containing all parent IDs of this map, 
    #i.e. the parent's ID, the parent's parent's ID, etc. 
    #The form of the array is descenending, i.e. the direct parent 
    #can be found at the end of the hash, whereas the parent that 
    #doesn't have a parent itself resides at the array's beginning. 
    def parent_ids
      return [] if @parent == 0
      parents = []
      parent = @parent
      until parent.nil?
        parents << parent.id
        parent = parent.parent
      end
      parents.reverse
    end
    
    #Destroys this map by removing it from the list of remembered maps. 
    #Don't use the map object after a call to this method anymore. 
    def delete!
      self.class.delete(self.id)
    end
    
    #Returns a MapField object describing the given position. 
    #Raises a RangeError if you try to access a position outside the map. 
    def [](x, y, z)
      if [x, y, z].any?{|val| val < 0}
        raise(RangeError, "Map position < 0 is invalid!")
      elsif x >= @table.size
        raise(RangeError, "X coordinate #{x} is out of range (< #{@table.size})!")
      elsif y >= @table[0].size
        raise(RangeError, "Y coordinate #{y} is out of range (< #{@table[0].size})!")
      elsif z >= @table[0][0].size
        raise(RangeError, "Z coordinate #{z} is out of range (< #{@table[0][0].size})!")
      end
      @table[x][y][z]
    end
    
    #Sets the field that should be used at the specified position. 
    #Raises a RangeError if you try to access a position outside the map. 
    #Call the #clear! method on a MapField if you want to "delete" it. 
    def []=(x, y, z, field)
      if [x, y, z].any?{|val| val < 0}
        raise(RangeError, "Map position < 0 is invalid!")
      elsif x >= @table.size
        raise(RangeError, "X coordinate #{x} is out of range (< #{@table.size})!")
      elsif y >= @table[0].size
        raise(RangeError, "Y coordinate #{y} is out of range (< #{@table[0].size})!")
      elsif z >= @table[0][0].size
        raise(RangeError, "Z coordinate #{z} is out of range (< #{@table[0][0].size})!")
      end
      @table[x][y][z] = field
    end
    
    #See accessor. 
    def name # :nodoc:
      @name.nil? || @name.empty? ? @id.to_s : @name
    end
    
    #See accessor. 
    def name=(str) # :nodoc
      @name = str.to_s
    end
    
    #Human-readable description of form 
    #  <OpenRubyRMK::GUI::Map ID: <map_id> Size: <width>x<height>x<depth>>
    #. 
    def inspect
      "<#{self.class} ID: #{@id} Size: #{@table.size}x#{@table[0].size}x#{@table[0][0].size}>"
    end
    
    #Saves this map to a file in OpenRubyRMK.project_maps_dir. and updates the structure file. 
    #See this class's documentation for a description of the file format. Always make sure that 
    #the parent map of this map has already been saved, otherwise you'll get a NoMethodError here 
    #and a serialized map, although the structure file hasn't been updated!
    def save
      #Convert from internal format to serialization format
      table = []
      @table.each do |col|
        table << []
        col.each do |depth_row|
          table.last << []
          depth_row.each do |field|
            table.last.last << (field.clear? ? [-1, -1, {}] : [field.mapset_x, field.mapset_y, {}]) #TODO - characters hash!
          end
        end
      end
      
      hsh = {
        :name => name, #@name may be unset
        :mapset => @mapset.filename.basename.to_s, 
        :table => table, 
        :parent => @parent.nil? ? 0 : @parent.id #0 means there's no parent
      }
      #Save the map
      OpenRubyRMK::Paths.project_maps_dir.join("#{@id}.bin").open("wb"){|f| Marshal.dump(hsh, f)}
      #Add it to the structure file
      orig_hsh = hsh = OpenRubyRMK::Paths.project_maps_structure_file.open("rb"){|f| Marshal.load(f)}
      ids = parent_ids
      until ids.empty?
        hsh = hsh[ids.shift] #By reference!
      end
      hsh[@id] = {}
      OpenRubyRMK::Paths.project_maps_structure_file.open("wb"){|f| Marshal.dump(orig_hsh, f)}
    end
    
  end
  
end