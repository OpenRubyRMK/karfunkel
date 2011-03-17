#!/usr/bin/env ruby
#Encoding: UTF-8

module OpenRubyRMK
  
  module Karfunkel
    
    module ServerManagement
    
      module Responses
        
        class FinishedResponse < Response
          
          def make_xml(xml)
            #Nothing to do here, we have no extra information to transmit
          end
          
        end
        
      end
      
    end
    
  end
  
end
