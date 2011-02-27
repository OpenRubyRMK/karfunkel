#!/usr/bin/env ruby
#Encoding: UTF-8

module OpenRubyRMK
  
  module Karfunkel
    
    module ServerManagement
    
      module Responses
        
        class OKResponse < Response
          
          #Pass in a hash of#key-value pairs that shall be presented to the
          #client.
          def initialize(request, hsh)
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
