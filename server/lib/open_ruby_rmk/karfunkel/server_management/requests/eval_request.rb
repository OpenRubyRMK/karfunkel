#!/usr/bin/env ruby
#Encoding: UTF-8

module OpenRubyRMK
  
  module Karfunkel
    
    module ServerManagement
    
      module Requests
        
        class EvalRequest < Request
          
          #The sourcode that shell be evaluated.
          attr_accessor :code
          
          def self.parse_xml!(request_node, obj)
            obj.code = request_node.at_xpath("code")
          end
          
          def start(client)
            unless Karfunkel.debug_mode?
              reject("Karfunkel is not running in debug mode.")
              Karfunkel.log_warn("[#{@client}] Rejected an EVAL request.")
              @alive = false
              return
            end
            
            Karfunkel.log_debug("Executing EVAL request.")
            res = Responses::OKResponse.new(@request_id, type)
            begin
              res = eval(@code)
            rescue Exception => e
              Karfunkel.log_exception(e)
              cmd.info(:exception => e.class.name, :message => e.message, :backtrace => e.backtrace.join("\n"))
            else
              cmd.info(:result => res.inspect)
            ensure
              cmd = Command.new(Karfunkel.client)
              cmd << res
              cmd.deliver!(client)
              Karfunkel.log_debug("Finished executing EVAL request.")
            end
          end
          
          private
          
          def make_xml(xml)
            raise(Errors::InvalidParameter, "No code given!") unless @code
            xml.code @code
          end
          
        end
        
      end
      
    end
    
  end
  
end
