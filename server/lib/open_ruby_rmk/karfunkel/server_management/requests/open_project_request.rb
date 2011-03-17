#!/usr/bin/env ruby
#Encoding: UTF-8

module OpenRubyRMK
  
  module Karfunkel
    
    module ServerManagement
    
      module Requests
        
        class OpenProjectRequest < Request
          
          #The project file this request refers to.
          attr_accessor :file
          
          def self.parse_xml!(request_node, obj)
            obj.file = request_node.at_xpath("file")
          end
          
          def start(client)
            cmd = Command.new(Karfunkel)
            
            @project = PM::Project.load(@file)
            Karfunkel.log_info("Loading project '#{@project.name}'.")
            Karfunkel.projects << @project
            
            res = Responses::ProcessingResponse.new(@request_id, type)
            res.info = {:mapset_extraction => 0, :char_extraction => 0}
            cmd << res
            cmd.deliver!(client)
            
            timer = EventMachine.add_periodic_timer(2) do
              cmd = Command.new(Karfunkel)
              
              unless @project.loaded?
                res = Responses::ProcessingResponse.new(@request_id, type)
                res.info = @project.loading
                cmd << res
                cmd.deliver!(client)
              else
                Karfunkel.log_info("Finished loading project '#{@project.name}'.")
                res = Responses::FinishedResponse.new(@request_id, type)
                cmd << res
                cmd.deliver!(client)
                #Cleanup
                @alive = false
                timer.cancel
              end
            end
          end
          
          private
          
          def make_xml(xml)
            raise(Errors::InvalidParameter, "No project file given!") unless @file
            raise(Errors::InvalidParameter, "Not a file: #{params["file"]}!") unless File.file?(@file)
            xml.file @file
          end
          
        end
        
      end
      
    end
    
  end
  
end
