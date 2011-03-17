#!/usr/bin/env ruby
#Encoding: UTF-8

module OpenRubyRMK
  
  module Karfunkel
    
    module ServerManagement
    
      module Responses
        
        class RejectedResponse < Response
          
          #The reason why the corresponding request was rejected.
          #Generates a REASON tag. Mandatory.
          attr_accessor :reason
          
          def make_xml(xml)
            raise(ArgumentError, "No reason given!") unless @reason
            xml.reason @reason
          end
          
        end
        
      end
      
    end
    
  end
  
end
