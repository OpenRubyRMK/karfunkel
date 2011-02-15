#!/usr/bin/env ruby
#Encoding: UTF-8

module OpenRubyRMK
  
  module Karfunkel
    
    module Requests
      
      class EvalRequest < Request
        
        def start
          unless Karfunkel.debug_mode?
            reject("Karfunkel is not running in debug mode.")
            Karfunkel.log_warn("[#{@client}] Rejected an EVAL request.")
            @client.requests.delete(self)
            return
          end
          
          Karfunkel.log_debug("Executing EVAL request.")
          begin
            res = eval(@parameters["code"])
          rescue Exception => e
            Karfunkel.log_exception(e)
            ok(:exception => e.class.name, :message => e.message, :backtrace => e.backtrace.join("\n"))
          else
            ok(:result => res.inspect)
          ensure
            Karfunkel.log_debug("Finished executing EVAL request.")
          end
        end
        
        private
        
        def validate_parameters(params)
          raise(Errors::InvalidParameter, "No code given!") unless params.has_key?("code")
        end
        
      end
      
    end
    
  end
  
end
