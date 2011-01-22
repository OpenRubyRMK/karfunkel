#!/usr/bin/env ruby
#Encoding: UTF-8

module OpenRubyRMK
  
  module Karfunkel
    
    module Requests
      
      class Request
        
        def initialize(client, request_id, parameters)
          @client = client
          @request_id = request_id
          @parameters = parameters
          validate_parameters(@parameters)
        rescue Errors::InvalidParameter => e
          Karfunkel.log_exception(e)
          reject("Invalid parameter: #{e.message}")
        end
        
        def start
          raise(NotImplementedError, "This method has to be overriden in a subclass!")
        end
        
        #call-seq:
        #  eql?(other) → true or false
        #  self == other → true or false
        #
        #Two requests are considered equal if they
        #are associated with the same client and have the
        #same request ID.
        def eql?(other)
          @client == other.client and @request_id == other.request_id
        end
        alias == eql?
        
        #Human-readable description of form
        #  #<OpenRubyRMK::Karfunkel::Requests::Request ID=<id_here>>
        def inspect
          "#<#{self.class} ID: #{@request_id}>"
        end
        
        def to_s
          self.class.name.split("::").last
        end
        
        private
        
        def validate_parameters(parameters)
          raise(NotImplementedError, "This method has to be overriden in a subclass!")
        end
        
        def reject(reason)
          builder = Nokogiri::XML::Builder.new(encoding: "UTF-8") do |xml|
            xml.Karfunkel(:id => Karfunkel::ID) do
              xml.response(:type => self.to_s, :id => @request_id) do
                xml.status Protocol::REJECTED
                xml.reason(reason)
              end
            end
          end
          @client.connection.send_data(builder.to_xml + Protocol::END_OF_COMMAND)
          #A rejected request is dead. Remove it.
          @client.requests.delete(self)
        end
        
        def send_data(str)
          @client.connection.send_data(str)
        end
        
      end
      
    end
    
  end
  
end
