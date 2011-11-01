# -*- coding: utf-8 -*-

#This is a mixin module mixed into the connections made to
#Karfunkel. The public methods are called by EventMachine,
#the private ones are helper methods.
#To clarify: Each time a new client connects to Karfunkel,
#an anonymous class created and instanciated by EventMachine
#(whatever for) and this module (as specified in the
#Karfunkel.start method) is mixed into that class. See also the
#EventMachine documentation.
#
#Whenever the user sends a complete command, #process_command
#is triggered which instantiates an instance of one of the
#classes in the Requests module. These are generated from the
#files in the *lib/open_ruby_rmk/karfunkel/server_management/requests*
#directory.
module OpenRubyRMK::Karfunkel::Plugins::Core::Protocol
    
  #This is the byte that terminates each command.
  END_OF_COMMAND = "\0".freeze
  
  #The client that sits on the other end of the connection.
  attr_reader :client
  
  #Called by EventMachine immediately after a connection try
  #was made.
  def post_init
    @client = Client.new(self)
    OpenRubyRMK::Karfunkel::THE_INSTANCE.clients << @client
    OpenRubyRMK::Karfunkel::THE_INSTANCE.log_info("Connection try from #{client}.")
    #We may get an incomplete command over the network, so we have
    #to collect the received data until the End Of Command marker,
    #which I defined to be a NUL byte, is encountered. Then
    ##receive_data calls #process_command with the full command
    #and empties the @received_data instance variable.
    @received_data = ""
    #Sometime Karfunkel needs to send requests as well, and these
    #requests need an ID. This ID is counted up by means of incrementing
    #this variable. See also the #next_request_id method.
    @last_request_id = -1
    #This is the mutex that ensures that the incrementing is stable
    #across threads.
    @last_request_id_mutex = Mutex.new
    #If the client doesn't authenticate within X seconds, disband
    #him.
    EventMachine.add_timer(OpenRubyRMK::Karfunkel::THE_INSTANCE.config[:greet_timeout]) do
      if !@client.authenticated?
        OpenRubyRMK::Karfunkel::THE_INSTANCE.log_warn("[#@client] Connection timeout for #{@client}.")
        terminate!
      end
    end
    #Clients that do not answer requests can be considered uninterested.
    #Therefore we sent him every now and then a PING request. If he
    #doesn’t answer, he’s disconnected.
    @ping_timer = EventMachine.add_periodic_timer(OpenRubyRMK::Karfunkel::THE_INSTANCE.config[:ping_interval]) do
      @client.available = false
      @client.request(OpenRubyRMK::Karfunkel::Plugins::Core::Requests::Ping.new(OpenRubyRMK::Karfunkel::THE_INSTANCE, next_request_id))
      #Now wait for the client to respond to the PING, and if
      #he doesn’t, disconnect.
      EventMachine.add_timer(OpenRubyRMK::Karfunkel::THE_INSTANCE.config[:ping_interval] - 1) do #-1, b/c another PING request could be sent otherwise
        unless @client.available?
          OpenRubyRMK::Karfunkel::THE_INSTANCE.log_warn("[#@client] No response to PING. Disconnecting #@client.")
          terminate!
        end
      end
    end
  end
  
  #Called by EventMachine when data has been sent to
  #the server.
  def receive_data(data)
    #Collect the sent data...
    @received_data << data #TODO: Attacker could exhaust memory by sending no NULs
    #...until we get the End Of Command marker. Then we know that
    #the command is completed and we can process it.
    #Empty the command cache afterwards.
    if @received_data.end_with?(END_OF_COMMAND)
      process_command(@received_data.sub(/#{END_OF_COMMAND}$/, ""))
      @received_data.clear
    end
  end
  
  #Called by EventMachine when this connection has been
  #closed.
  def unbind
    @ping_timer.cancel
    OpenRubyRMK::Karfunkel::THE_INSTANCE.clients.delete(@client)
    OpenRubyRMK::Karfunkel::THE_INSTANCE.log_info("Connection to #{@client} closed.")
  end
  
  private
  
  #For easier typing, resolves to OpenRubyRMK::Karfunkel::THE_INSTANCE.
  def karfunkel
    OpenRubyRMK::Karfunkel::THE_INSTANCE
  end

  #Processes a full command. If the client sending the command
  #was not yet authenticated, #check_authentication is invoked to
  #authenticate the client (or reject him).
  #
  #This method shouldn’t crash, but rather log exceptions and
  #warnings, continueing the event loop.
  def process_command(command_xml)
    #First we parse the command.
    begin
      command = OpenRubyRMK::Karfunkel::Plugins::Core::Command.from_xml(command_xml, @client)
    rescue => e
      OpenRubyRMK::Karfunkel::THE_INSTANCE.log_exception(e)
      error(e.message)
      return
    end
    
    #We received data from the client, so he’s available!
    #This is enough to answer a PING request.
    @client.available = true
    
    #Ensure the user is allowed to demand requests. If not, try to
    #authenticate him.
    begin
      check_authentication(command)
    rescue OpenRubyRMK::Errors::AuthenticationError => e
      OpenRubyRMK::Karfunkel::THE_INSTANCE.log_warn("[#@client] Authentication failed: #{e.message}")
      reject("Authentication failed.")
      terminate!
      return
    end
    
    #Then we execute all the requests
    command.requests.each do |request|
      begin
        OpenRubyRMK::Karfunkel::THE_INSTANCE.log_info("[#@client] Request: #{request.type}")
        request.execute!
      rescue => e
        OpenRubyRMK::Karfunkel::THE_INSTANCE.log_exception(e)
        reject(e.message, request)
      end
    end
    
    #And now we check the responses that Karfunkel’s clients send to us.
    command.responses.each do |response|
      begin
        OpenRubyRMK::Karfunkel::THE_INSTANCE.log_info("[#@client] Received response to a #{response.request.type} request")
        response.request.process_response(response)
        @client.sent_requests.delete(response.request)
      rescue => e
        OpenRubyRMK::Karfunkel::THE_INSTANCE.log_exception(e)
        OpenRubyRMK::Karfunkel::THE_INSTANCE.log_error("[#@client] Failed to process response: #{response}")
      end
    end
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
      raise(OpenRubyRMK::Errors::AuthenticationError.new(@client), "Client #@client tried to execute requests together with HELLO!")
    elsif command.requests.first.type != "Hello"
      raise(OpenRubyRMK::Errors::AuthenticationError.new(@client), "Client #@client tried to send another request than a HELLO!")
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
    r = OpenRubyRMK::Karfunkel::Plugins::Core::Response.new(OpenRubyRMK::Karfunkel::THE_INSTANCE, request, :rejected)
    r[:reason] = reason
    @client.response(r)
  end
  
  #Sends an +error+ response to the client.
  #===Parameters
  #[description] Explanation on what went wrong.
  #[request]     (nil) An optional Request object used to fill the
  #              +type+ and +id+ attributes of the response.
  def error(description, request = nil)
    r = OpenRubyRMK::Karfunkel::Plugins::Core::Response.new(OpenRubyRMK::Karfunkel::THE_INSTANCE, request, :error)
    r[:description] = description
    @client.response(r)
  end
  
  #Threadsafely increments the request ID and returns the next
  #available ID.
  def next_request_id
    @last_request_id_mutex.synchronize do
      @last_request_id += 1
    end
  end
  
  #Immediately cuts the connection to Karfunkel,
  #setting the client's availability status to false.
  def terminate!
    @client.available = false
    @client.authenticated = false
    close_connection
  end
  
end
