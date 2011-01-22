#!/usr/bin/env ruby
#Encoding: UTF-8

module OpenRubyRMK
  
  module Karfunkel
    
    module Requests
      
      class OpenProjectRequest < Request
        
        def start
          send_data("Du bist doof.\0")
        end
        
        private
        
        def validate_parameters(params)
          raise(Errors::InvalidParameter, "No project file given!") unless params.has_key?("file")
          raise(Errors::InvalidParameter, "Not a file: #{params["file"]}!") unless File.file?(params["file"])
        end
        
      end
      
    end
    
  end
  
end
