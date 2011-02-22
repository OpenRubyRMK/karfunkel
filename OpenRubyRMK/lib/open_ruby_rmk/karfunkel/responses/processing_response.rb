#!/usr/bin/env ruby
#Encoding: UTF-8

module OpenRubyRMK
  
  module Karfunkel
    
    module Responses
      
      class ProcessingResponse < Response
        
        #Pass in a hash
        #containg the information you want to send back. The hash keys will
        #be used as XML nodes, and the values... Well, as the values.
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
