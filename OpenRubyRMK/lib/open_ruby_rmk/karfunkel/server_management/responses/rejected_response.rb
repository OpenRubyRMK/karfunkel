#!/usr/bin/env ruby
#Encoding: UTF-8

module OpenRubyRMK
  
  module Karfunkel
    
    module ServerManagement
    
      module Responses
        
        class RejectedResponse < Response
          
          #Just pass in why you reject the request.
          def initialize(request, reason)
            super(request)
            @reason = reason
          end
          
          def build_xml(xml)
            xml.reason @reason
          end
          
          #The request object will be deleted from the client afterwards.
          def post_deliver
            #A rejected request is dead. Remove it.
            @request.client.requests.delete(self)
          end
          
        end
        
      end
      
    end
    
  end
  
end
