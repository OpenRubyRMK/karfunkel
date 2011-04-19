#!/usr/bin/env ruby
#Encoding: UTF-8

module OpenRubyRMK
  
  module Karfunkel
    
    module ServerManagement
    
      module Requests
        
        class SelectProjectRequest < Request
          
          #The project this request wants to load.
          attr_accessor :name
          
          def self.parse_xml!(request_node, obj)
            obj.name = request_node.at_xpath("name")
          end
          
          def start(client)
            cmd = Command.new(Karfunkel)
            
            begin
              Karfunkel.select_project_by_index(Karfunkel.projects.index{|proj| proj.name == @name})
              res = Responses::OKResponse.new(@request_id, type)
              cmd << res
            rescue => e
              Karfunkel.log_exception(e)
              res = Responses::RejectedResponse.new(@request_id, type)
              res.reason = "#{e.class}: #{e.message}"
              cmd << res
            end
            cmd.deliver!(client)
          end
          
          private
          
          def make_xml(xml)
            raise(Errors::InvalidParameter, "No project name given!") unless @name
            xml.name @name
          end
          
        end
        
      end
      
    end
    
  end
  
end
