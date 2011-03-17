#!/usr/bin/env ruby
#Encoding: UTF-8

module OpenRubyRMK
  
  module Karfunkel
    
    module ServerManagement
    
      module Responses
        
        class ErrorResponse < Response
          
          attr_accessor :message
          
          def make_xml(xml)
            raise(ArgumentError, "Errors need to have a message!") unless @message
            xml.message @message
          end
          
        end
        
      end
      
    end
    
  end
  
end