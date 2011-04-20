#!/usr/bin/env ruby
#Encoding: UTF-8

module OpenRubyRMK
  
  module Karfunkel
    
    module ServerManagement
    
      #This is a mixin module mixed into the connections made to
      #Karfunkel. The public methods are called by EventMachine,
      #the private ones are helper methods.
      #
      #Whenever the user sends a complete command, #process_command
      #is triggered which instantiates an instance of one of the
      #classes in the Requests module. These are generated from the
      #files in the *lib/open_ruby_rmk/karfunkel/server_management/requests*
      #directory.
      module Protocol
        
        #This is the byte that terminates each command.
        END_OF_COMMAND = "\0".freeze
        
        #The client that sits on the other end of the connection.
        attr_reader :client
        
        #Called by EventMachine immediately after a connection try
        #was made.
        def post_init
          @client = Client.new(self)
          Karfunkel.clients << @client
          Karfunkel.log_info("Connection try from #{client}.")
          #We may get an incomplete command over the network, so we have
          #to collect the received data until the End Of Command marker,
          #which I defined to be a NUL byte, is encountered. Then
          ##receive_data calls #process_command with the full command
          #and empties the @received_data instance variable.
          @received_data = ""
          #As we may sent multiple requests/responses in one command,
          #we have to cache them somewhere. Ideally in a Command. This gets
          #sent and cleared each time a full command has been processed. Note
          #however that the server may generate Commands aside this cache,
          #because it is not inspected on a regular basis (the receive_data
          #method is only called when data was received).
          @cached_command = Command.new(Karfunkel)
          #Sometime Karfunkel needs to send requests as well, and these
          #requests need an ID. This ID is counted up by means of incrementing
          #this variable. See also the #next_request_id method.
          @last_request_id = -1
          #If the client doesn't authenticate within X seconds, disband
          #him.
          EventMachine.add_timer(Karfunkel.config[:greet_timeout]) do
            if !@client.authenticated?
              Karfunkel.log_warn("Connection timeout for #{@client}.")
              terminate!
            end
          end
          #Clients that do not answer requests can be considered uninterested.
          #Therefore we sent him every now and then a PING request. If he
          #doesn’t answer, he’s disconnected.
          EventMachine.add_periodic_timer(Karfunkel.config[:ping_interval]) do
            Karfunkel.log_info("[#@client] Sending PING to #@client")
            @client.available = false
            cmd = Command.new(Karfunkel)
            req = Requests::PingRequest.new(next_request_id)
            cmd.requests << req
            cmd.deliver!(@client)
            @client.sent_requests << req
            #Now wait for the client to respond to the PING, and if
            #he doesn’t, disconnect.
            EventMachine.add_timer(Karfunkel.config[:ping_interval] - 1) do #-1, b/c another PING request could be sent then
              Karfunkel.log_warn("[#@client] No response to PING. Disconnecting #@client.")
              terminate! unless @client.available?
            end
          end
        end
        
        #Called by EventMachine when data has been sent to
        #the server.
        def receive_data(data)
          #Collect the sent data...
          @received_data << data
          #...until we get the End Of Command marker. Then we know that
          #the command is completed and we can process it.
          #Empty the command cache afterwards.
          if @received_data.end_with?(END_OF_COMMAND)
            process_command(@received_data.sub(/#{END_OF_COMMAND}$/, ""))
            deliver_answer_command
            #remove_dead_requests_and_responses
            @received_data.clear
            @cached_command = Command.new(Karfunkel)
          end
        end
        
        #Called by EventMachine when this connection has been
        #closed.
        def unbind
          Karfunkel.clients.delete(@client)
          Karfunkel.log_info("Connection to #{@client} closed.")
        end
        
        private
        
        #Processes a full command. If the client sending the command
        #was not yet authenticated, #check_authentication is invoked to
        #authenticate the client (or reject him). Otherwise, first
        #processes the commands’s requests and then it’s responses, collecting
        #all wanted responses in the @cached_command command.
        #
        #This method shouldn’t crash, but rather log exceptions and
        #warnings, continueing the event loop.
        def process_command(command_xml)
          #First we parse the command.
          begin
            command = Command.from_xml(command_xml, @client)
          rescue => e
            Karfunkel.log_exception(e)
            error(e.message)
            return
          end
          
          #We received data from the client, so he’s available!
          @client.available = true
          
          #Ensure the user is allowed to demand requests. If not, try to
          #authenticate him.
          begin
            check_authentication(command)
          rescue Errors::AuthenticationError => e
            Karfunkel.log_warn("[#@client] Authentication failed: #{e.message}")
            reject("Authentication failed.")
            terminate!
            return
          end
          
          #Then we execute all the requests
          command.requests.each do |request|
            begin
              Karfunkel.log_info("[#@client] Request: #{request.type}")
              @cached_command.responses << request.execute(@client)
            rescue => e
              Karfunkel.log_exception(e)
              reject(e.message, request)
            end
          end
          
          #And now we check the responses that Karfunkel’s clients send to us.
          command.responses.each do |response|
            begin
              Karfunkel.log_info("[#@client] Response to #{response.request.type} request")
              response.request.process_response(@client, response)
              @client.sent_requests.delete(response.request)
            rescue => e
              Karfunkel.log_exception(e)
              Karfunkel.log_error("[#@client] Failed to process response: #{response}")
            end
          end
        end
        
        #Sends anything that has been put into @cached_command to the client.
        #If nothing has been collected there, nothing is send.
        def deliver_answer_command
          return if @cached_command.empty? #We don't want to send empty commands.
          @cached_command.deliver!(@client)
        end
        
        #Removes all requests and responses from this client that have been
        #processed completely.
        def remove_dead_requests_and_responses
          @client.requests.delete_if{|req| !req.alive?}
          @client.sent_requests.delete_if{|req| !req.alive?}
          @client.responses.delete_if{|res| !res.alive?}
        end
        
        #Checks if the user is authenticated, and if so, immediately
        #returns. If not, this method verifies that +command+ contains
        #a single +Hello+ request and nothing else. Note that this
        #method just detects structural errors, because the actual
        #authentication takes place during the execution of the
        #+Hello+ request.
        def check_authentication(command)
          return if @client.authenticated?
          #OK, not authenticated. This means, the first request the client
          #sends must be HELLO, and no further requests in this command are
          #allowed.
          if command.requests.count > 1
            raise(AuthenticationError.new(@client), "Client #@client tried to execute requests together with HELLO!")
          elsif command.requests.first.type != "Hello"
            raise(AuthenticationError.new(@client), "Client #@client tried to send another request than a HELLO!")
          end
          #Good, no malicious attempts so far. Return and let the HelloRequest
          #class check credentials, etc.
        end
        
        #Sends a +rejected+ response to the client.
        #===Parameters
        #[reason]  Reason why the client was rejected.
        #[request] (nil) An optional Request object used to fill the
        #          +type+ and +id+ attributes of the response.
        def reject(reason, request = nil)
          r = Response.new(request, :rejected)
          r[:reason] = reason
          @cached_command.responses << r
        end
        
        #Sends an +error+ response to the client.
        #===Parameters
        #[description] Explanation on what went wrong.
        #[request]     (nil) An optional Request object used to fill the
        #              +type+ and +id+ attributes of the response.
        def error(description, request = nil)
          r = Response.new(request, :error)
          r[:description] = description
          @cached_command.responses << r
        end
        
        def next_request_id
          @last_request_id += 1
        end
        
        #Immediately cuts the connection to Karfunkel,
        #setting the client's availability status to false.
        def terminate!
          close_connection
        end
        
      end
      
    end
    
  end
  
end
