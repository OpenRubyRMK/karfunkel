#!/usr/bin/env ruby
#Encoding: UTF-8

module OpenRubyRMK
  
  module Karfunkel
    
    module ServerManagement
      
      module Requests
        
        #This is the base class for all request classes. Everything that
        #Karfunkel can do is transmitted via requests, and these requests
        #are represented by subclasses of this class.
        #
        #The lifecylce of a request object is as follows:
        #
        #1. The user sends the command XML.
        #2. Protocoll#receive_data calls Protocoll#process_command, which in
        #   turn instanciated the appropriate Request subclass, passing it the
        #   Client object that made the request, the command ID and the
        #   parameters the user transmitted along with the request.
        #3. The #process_command method then calls Request#start, in which
        #   some kind of response must be issued. Either put a +processing+
        #   response, or answer directly with +ok+ (or something appropriate)
        #   for things that don't take too long.
        #4. After the final response was made, the request deletes itself from
        #   the list of requests associated with the client (available via the
        #   Client#requests attribute).
        #
        #Those requests that take long to complete should notify the client
        #from time to time via a +processing+ response and finally with a
        #+finished+ response when completed. Use EventMachine's +add_timer+ and
        #+add_periodic_timer+ methods in combination with EventMachine.defer to
        #make your processing executing in parallel. If you do not want to use
        #EventMachine.defer for some reason (e.g. you already create threads
        #inside a library method), use normal threads or processes. This is fine.
        class Request
          
          #The ID the client assigned to this request.
          attr_reader :request_id
          
          def self.from_xml(xml)
            request_node = xml.kind_of?(Nokogiri::XML::Node) ? xml : parse_request(xml)
            
            obj = new(request_node["id"])
            parse_xml!(request_node, obj)
            obj
          end
          
          #Gets the Nokogiri::XML::Node object of the request and the not yet
          #complete Request object passed. In subclasses, this method then must
          #set all attributes specific to the subclass on +obj+.
          def self.parse_xml!(request_node, obj)
            raise(NotImplementedError, "This method must be implemented in a subclass!")
          end
          
          #Creates a new Request object for the specified Client with the given
          #+request_id+ and +parameters+. This method is called by
          #Protocol#process_command each time a valid request is found.
          def initialize(request_id)
            @request_id = request_id
            @alive = true
          end
          
          #This method is immediately called by Protocol#process_command
          #immediately after the Request subclass has been instanciated. If your
          #request can be processed quickly, you can answer the request here
          #(via #send_data), otherwise issue a +processing+ response and create
          #a new thread (or even process) for your work. Be sure to send a
          #+finished+ response from the thread when the work is done.
          #
          #If it wasn't clear to you: YES, you have to override this method
          #in your subclasses.
          def start
            raise(NotImplementedError, "This method has to be overriden in a subclass!")
          end
          
          #call-seq:
          #  eql?(other) → true or false
          #  self == other → true or false
          #
          #Two requests are considered equal if they
          #have the same request ID.
          def eql?(other)
            @request_id == other.request_id
          end
          alias == eql?
          
          #Human-readable description of form
          #  #<OpenRubyRMK::Karfunkel::Requests::Request ID=<id_here>>
          def inspect
            "#<#{self.class} ID: #{@request_id}>"
          end
          
          def type
            self.class.name.split("::").last.match(/Request$/).pre_match
          end
          
          #The name of this request, automatically obtained by removing all
          #namespaces from the class's name.
          def to_s
            type.to_s
          end
          
          def build_xml!(parent_node = nil)
            l = lambda do |xml|
              xml.request(:type => type, :id => @request_id) do
                make_xml
              end
            end
            
            if parent_node?
              Nokogiri::XML::Builder.with(parent_node, &l)
            else #Shouldn't be necessary, as this wouldn't be a correct Karfunkel command
              Nokogiri::XML::Builder.new(encoding: "UTF-8", &l)
            end
            
          end
          
          def build_xml
            build_xml!
          end
          
          #Returns true if this request is still being processed on
          #the server side.
          def alive?
            @alive
          end
          
          private
          
          def self.parse_request(str)
            xml = Nokogiri::XML(str, nil, nil, Nokogiri::XML::ParseOptions::STRICT | Nokogiri::XML::ParseOptions::NOBLANKS)
          rescue Nokogiri::XML::SyntaxError
            raise(Errors::MalformedCommand, "Malformed XML document.")
          end
          
          def make_xml(xml)
            raise(NotImplementedError, "This method has to be overriden in a subclass!")
          end
          
        end
        
      end
      
    end
    
  end
  
end
