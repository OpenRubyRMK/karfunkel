#!/usr/bin/env ruby
#Encoding: UTF-8

module OpenRubyRMK
  
  module Karfunkel
    
    module Requests
      
      class OpenProjectRequest < Request
        
        def start
          @project = Project.load(@parameters["file"])
          Karfunkel.log_info("Loading project '#{@project.name}'.")
          Karfunkel.projects << @project
          processing(mapset_extraction: 0, char_extraction: 0)
          
          timer = EventMachine.add_periodic_timer(2) do
            unless @project.loaded?
              processing(@project.loading)
            else
              Karfunkel.log_info("Finished loading project '#{@project.name}'.")
              finished
              #Cleanup
              @client.requests.delete(self)
              timer.cancel
            end
          end
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
