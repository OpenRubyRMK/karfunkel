#!/usr/bin/env ruby
#Encoding: UTF-8

module OpenRubyRMK
  
  module Karfunkel
    
    module ServerManagement
    
      module Responses
        
        class ProcessingResponse < Response
          
          #Indicates how many percent have already been finished.
          #If left out, the response simply won't have a PERCENT tag.
          attr_accessor :percent_done
          
          def make_xml(xml)
            xml.percent @percent_done if @percent_done
          end
          
        end
        
      end
      
    end
    
  end
  
end
