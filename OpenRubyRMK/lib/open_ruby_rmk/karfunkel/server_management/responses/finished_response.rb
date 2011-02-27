#!/usr/bin/env ruby
#Encoding: UTF-8

module OpenRubyRMK
  
  module Karfunkel
    
    module ServerManagement
    
      module Responses
        
        class FinishedResponse < Response
          
          #[hsh] ({}) If you want to tell your client about something,
          #pass in the usual key-value combination here.
          def initialize(request, hsh = {})
            super(request)
            @info = hsh
          end
          
          def build_xml(xml)
            @info.each_pair{|k, v| xml.send(k, v)}
          end
          
        end
        
      end
      
    end
    
  end
  
end
