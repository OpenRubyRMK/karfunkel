#!/usr/bin/env ruby
#Encoding: UTF-8

module OpenRubyRMK
  
  module Karfunkel
    
    module ServerManagement
    
      #This is a client that sits on the other end of the connection.
      #Objects of this class are automatically instanciated by the
      #Protocol module.
      class Client
        
        #The operating system a client uses.
        attr_accessor :os
        #The ID assigned to this client.
        attr_accessor :id
        #Wheather or not a client has already been authenticated.
        attr_accessor :authenticated
        #Wheather or not data can be send to this client.
        #This is set *manually* and does *not* check the
        #actual state of the connection.
        attr_accessor :available
        #The requests that are outstanding for this client, i.e. those
        #requests that have been received FROM the client and are
        #currently being processed.
        attr_accessor :requests
        #Responses this client has sent back.
        attr_accessor :responses
        #The requests that have been send TO the client.
        attr_accessor :sent_requests
        #The client's IP address.
        attr_reader :ip
        #The port the client uses for the connection.
        attr_reader :port
        #The connection this client is tied to.
        attr_reader :connection
        
        #Creates a new Client instance. Pass in the connection the
        #client uses.
        def initialize(connection)
          @connection = connection
          @authenticated = false
          @available = true
          @requests = []
          @sent_requests = []
          @responses = []
          @last_request_id = 0
          @request_id_generator_mutex = Mutex.new #This is a shared resource
          if peer = @connection.get_peername
            @port, @ip = Socket.unpack_sockaddr_in(peer)
          else
            @port = "?"
            @ip = "(unknown)"
          end
        end
        
        #True if the client is authenticated.
        def authenticated?
          @authenticated
        end
        
        #Generates a new and unused ID for requests sent TO the client.
        #For the IDs the client sends, he is responsible himself.
        def generate_request_id
          @request_id_generator_mutex.synchronize do
            @last_request_id += 1
          end
        end
        
        #True if the client can be sent data (see the attribute for further
        #explanation).
        def available?
          @available
        end
        
        #Human-readable description of form
        #  #<OpenRubyRMK::Karfunkel::Client <ipaddress>>
        def inspect
          "#<#{self.class} #{ip}>"
        end
        
        #The client's IP address.
        def to_s
          @ip
        end
        
      end
      
    end
    
  end
  
end
