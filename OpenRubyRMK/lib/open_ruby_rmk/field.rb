#!/usr/bin/env ruby
#Encoding: UTF-8

module OpenRubyRMK
  
  #A single field on a mapset or even on the map. 
  #
  #TODO: This class is quite small at the moment and just wraps a Wx::Image object, ALTHOUGH 
  #IT'S NOT IN THE GUI NAMESPACE. This class doesn't belong to the GUI, but... See the Mapset 
  #class for a more detailed explanation why this is wxRuby-dependant. 
  class Field
    
    #The underlying Wx::Image object. 
    attr_reader :image
    
    #Creates a new Field from a Wx::Image object. 
    def initialize(img)
      @image = img
    end
    
  end
  
end