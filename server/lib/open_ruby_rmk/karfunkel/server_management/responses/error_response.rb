#!/usr/bin/env ruby
#Encoding: UTF-8

module OpenRubyRMK
  
  module Karfunkel
    
    module ServerManagement
    
      module Responses
        
        class ErrorResponse < Response
          
          #The plain error message.
          attr_accessor :message
          #The error class's name.
          attr_accessor :name
          #What this means for the client.
          attr_accessor :conclusion
          
          def make_xml(xml)
            raise(ArgumentError, "Errors need to have a name!") unless @name
            raise(ArgumentError, "Errors need to have a message!") unless @message
            raise(ArgumentError, "Errors need to have a conclusion!") unless @conclusion
            xml.name @name
            xml.message @message
            xml.conclusion @conclusion
          end
          
        end
        
      end
      
    end
    
  end
  
end