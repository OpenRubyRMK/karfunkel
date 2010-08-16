#!/usr/bin/env ruby
#Encoding: UTF-8

module OpenRubyRMK
  
  #This is the namespace for anything GUI related. Classes inside this 
  #module aren't supposed to work without wxRuby. 
  module GUI
    
    #The name of the Grid type for a map field. 
    GRID_FIELD_TYPE = "MAP_FIELD".freeze
    
    #This enumerator emits available IDs for GUI controls. Just call #next on 
    #it when you want to get a free ID. 
    ID_GENERATOR = Enumerator.new(1000..INFINITY)
    
  end
  
end