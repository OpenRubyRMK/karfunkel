#!/usr/bin/env ruby
#Encoding: UTF-8

module OpenRubyRMK
  
  module Karfunkel
    
    #This is a client connected (or trying to connect) to Karfunkel.
    #There is no need to create any Client instances manually--they're
    #just a helper construct for Karfunkel.
    class Client
      
      #Actual TCP socket of the client.
      attr_reader :socket
      #The operating system the client uses. This can be
      #used for some compatibility operations.
      attr_accessor :os
      
      #Creates a new Client. Pass in the TCP socket object that
      #tries to make a connection to Karfunkel.
      def initialize(tcp_client)
        @socket = tcp_client
        @os = nil
      end
      
      #Human-readable description of form
      #  #<OpenRubyRMK::Karfunkel::Client hostname (ipaddress)>
      def inspect
        addr = @socket.peeraddr
        "#<#{self.class} #{addr[2]} (#{addr[3]})>"
      end
      
      #Transformation to a string of form
      #  hostname (ipaddress)
      def to_s
        addr = @socket.peeraddr
        addr[2] + " (" + addr[3] + ")"
      end
      
    end
    
  end
  
end
