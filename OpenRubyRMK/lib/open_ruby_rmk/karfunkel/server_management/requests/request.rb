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
          
          #The client that sent this request.
          attr_reader :client
          #The ID the client assigned to this request.
          attr_reader :request_id
          #The parameters the client handed to the request.
          attr_reader :parameters
          
          #Creates a new Request object for the specified Client with the given
          #+request_id+ and +parameters+. This method is called by
          #Protocol#process_command each time a valid request is found.
          def initialize(client, request_id, parameters)
            @client = client
            @request_id = request_id
            @parameters = parameters
            validate_parameters(@parameters)
          rescue Errors::InvalidParameter => e
            Karfunkel.log_exception(e)
            reject("Invalid parameter: #{e.message}")
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
          
          #The name of this request, automatically obtained by removing all
          #namespaces from the class's name.
          def to_s
            self.class.name.split("::").last
          end
          
          private
          
          #Subclasses should override this method and use it to check wheather
          #the arguments a user passes via a request are correct. Raise an
          #InvalidParameter error if they aren't.
          def validate_parameters(parameters)
            raise(NotImplementedError, "This method has to be overriden in a subclass!")
          end
          
          #Shortcut for calling #send_data with a +rejected+ respone. Just pass
          #in why you reject the request.
          #The request object will be deleted from the client afterwards.
          def reject(reason)
            Responses::RejectedResponse.new(self, reason).deliver!
          end
          
          #Shortcut for ending a +processing+ response to the waiting client. Pass in a hash
          #containg the information you want to send back. The hash keys will
          #be used as XML nodes, and the values... Well, as the values.
          def processing(hsh)
            Responses::ProcessingResponse.new(self, hsh).deliver!
          end
          
          #Shortcut for sending a +fnished+ response to the waiting client.
          #Pass a hash of key-value pairs if you want to tell the client
          #something.
          def finished(hsh = {})
            Responses::FinishedResponse.new(self, hsh).deliver!
          end
          
          #Shortcut for sending an +ok+ response. Pass in a hash of
          #key-value pairs that shall be presented to the client.
          def ok(hsh)
            Responses::OKResponse.new(self, hsh).deliver!
          end
          
        end
        
      end
      
    end
    
  end
  
end
