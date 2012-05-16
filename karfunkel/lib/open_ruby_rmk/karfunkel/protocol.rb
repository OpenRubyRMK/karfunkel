# -*- coding: utf-8 -*-

module OpenRubyRMK

  #This is a mixin module mixed into the connections made to
  #Karfunkel. The public methods are called by EventMachine,
  #the private ones are helper methods.
  #To clarify: Each time a new client connects to Karfunkel,
  #an anonymous class created and instanciated by EventMachine
  #(whatever for) and this module (as specified in the
  #core-hooked Karfunkel#start method) is mixed into that class.
  #See also the EventMachine documentation.
  #
  #== How sending and receiving works
  #After the OpenRubyRMK::Karfunkel class was instanciated,
  #Karfunkel starts listening on a port defined in the config
  #file (3141 by default). Then the following takes place:
  #
  #1. A possible client tries to establish a connection. This
  #   causes the #post_init method to be called.
  #2. #post_init instanciates the Karfunkel::Client class
  #   with the given information and adds the resulting instance
  #   to an internal array of connected clients. Then Karfunkel
  #   waits for the client to greet him. If he doesn’t greet in time
  #   (specified in the config file), Karfunkel rudely closes the
  #   connection.
  #3. The client sends a +Hello+ request. As with all sent data,
  #   this triggers the #receive_data method which in turn,
  #   when a _complete_ command has been received, calls
  #   the (private) #process_command method. (Complete commands
  #   are detected by receiving the END_OF_COMMAND byte, which
  #   should be a NUL byte.)
  #4. #process_command creates an instance of the
  #   OpenRubyRMK::Common::Command class by parsing the received XML.
  #5. If the client hasn’t been authenticated yet (as is the case
  #   when sending the first request), #process_command checks
  #   wheather the first and only request is a +Hello+ request. If this
  #   isn’t the case, the connection is immediately terminated.
  #6. Otherwise, #process_command processes each received
  #   request in turn (which in case of the first request
  #   obviously includes the +Hello+ request) and looks for a plugin
  #   that is able to handle requests of the given type. If one is found,
  #   the request is handed to the plugin for execution (Plugin#process_request).
  #   E.g., for the +Hello+ request, it finds the +Core+ plugin which
  #   currently just accepts the connection, but it could do
  #   things like password authentication.
  #7. After processing the requests, process any received responses
  #   the same way requests are processed. Any requests completely
  #   answered by responses are automatically deleted from the list
  #   of remembered requests (see the Transformator class for
  #   information on this).
  #8. Go to 5.
  #9. On disconnect, the #unbind method is called by EventMachine,
  #   which removes the client from the list of connected clients
  #   and cancels the ping timer for this client.
  module Karfunkel::Protocol
    include Karfunkel::CommandHelpers
    
    #This is the byte that terminates each command.
    END_OF_COMMAND = "\0".freeze
    
    #The client that sits on the other end of the connection.
    #A Core::Client object.
    attr_reader :client
    #The Transformer instance responsible for parsing and converting XML.
    attr_reader :transformer
    
    #Called by EventMachine immediately after a connection try
    #was made.
    def post_init
      @client      = Karfunkel::Client.new(self)
      @transformer = Common::Transformer.new
      Karfunkel::THE_INSTANCE.clients << @client
      Karfunkel::THE_INSTANCE.log.info("Connection try from #{client}.")
      #We may get an incomplete command over the network, so we have
      #to collect the received data until the End Of Command marker,
      #which I defined to be a NUL byte, is encountered. Then
      ##receive_data calls #process_command with the full command
      #and empties the @received_data instance variable.
      @received_data = ""
      #If the client doesn't authenticate within X seconds, disband
      #him.
      EventMachine.add_timer(Karfunkel::THE_INSTANCE.config[:greet_timeout]) do
        if !@client.authenticated?
          Karfunkel::THE_INSTANCE.log.warn("[#@client] Connection timeout for #{@client}.")
          terminate!
        end
      end
      #Clients that do not answer requests can be considered uninterested.
      #Therefore we sent him every now and then a PING request. If he
      #doesn’t answer, he’s disconnected.
      @ping_timer = EventMachine.add_periodic_timer(Karfunkel::THE_INSTANCE.config[:ping_interval]) do
        @client.available = false
        Karfunkel::THE_INSTANCE.deliver_request(Common::Request.new(Karfunkel::THE_INSTANCE.generate_request_id, :Ping), @client.id)
        #Now wait for the client to respond to the PING, and if
        #he doesn’t, disconnect.
        EventMachine.add_timer(Karfunkel::THE_INSTANCE.config[:ping_interval] - 1) do #-1, b/c another PING request could be sent otherwise
          unless @client.available?
            Karfunkel::THE_INSTANCE.log.warn("[#@client] No response to PING. Disconnecting #@client.")
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
      Karfunkel::THE_INSTANCE.clients.delete(@client)
      Karfunkel::THE_INSTANCE.log.info("Connection to #{@client} closed.")
    end
    
    private

    #Processes a full command. If the client sending the command
    #was not yet authenticated, #check_authentication is invoked to
    #authenticate the client (or reject him).
    #
    #This method shouldn’t crash, but rather log exceptions and
    #warnings, continueing the event loop.
    def process_command(command_xml)
      #First we parse the command.
      begin
        command = @transformer.parse!(command_xml)
      rescue => e
        Karfunkel::THE_INSTANCE.log_exception(e)
        error(@client, :message => e.message)
        return
      end
      
      #We received data from the client, so he’s available!
      #This is enough to answer a PING request.
      @client.available = true

      # Process the requests
      command.requests.each do |req|
        begin
          Karfunkel.instance.log.info("[#@client] Request: #{req.type}")
          reject(@client, req, :reason => "Not authenticated") and next if !client.authenticated? and !req.type == :hello
          Karfunkel.handle_request(client, req)
        rescue => e
          Karfunkel.instance.log_exception(e)
          reject(@client, req, :reason => e.message)
        end
      end

      # Process the responses
      commands.responses.each do |res|
        begin
          Karfunkel.instance.log.info("[#@client] Response: #{res.req.type}")
          log.warn("[#@client] Ignoring unauthenticated response") and next if !client.authenticated?
          Karfunkel.instance.handle_response(client, res)
        rescue => e
          Karfunkel.instance.log_exception(e)
          # Responses don’t need an answer
        end
      end

    rescue => e
      Karfunkel::THE_INSTANCE.log.fatal("[#@client] FATAL: Unhandled exception!")
      raise # Reraise
    end
    
    #Immediately cuts the connection to Karfunkel,
    #setting the client's availability status to false.
    def terminate!
      @client.available     = false
      @client.authenticated = false
      close_connection
    end
    
  end

end
