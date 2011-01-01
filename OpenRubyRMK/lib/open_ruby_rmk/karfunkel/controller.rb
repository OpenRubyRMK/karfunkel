#!/usr/bin/env ruby
#Encoding: UTF-8

module OpenRubyRMK
  
  module Karfunkel
    
    #This class solely exists, because I didn't want to mess up karfunkel.rb
    #with all the commands the Karfunkel server understands. Every command
    #is represanted as a method implemented for this class.
    class Controller
      
      KARFUNKEL_ID = 0
      GREET_TIMEOUT = 5
      ID_GENERATOR = (1..Float::INFINITY).enum_for(:each)
      
      OK = "OK".freeze
      FINISHED = "Finished".freeze
      FAILED = "Failed".freeze
      PROCESSING = "Processing".freeze
      REJECTED = "Rejected".freeze
      
      #Creates a new Controller for the given Karfunkel instance.
      def initialize(karfunkel)
        @karfunkel = karfunkel
        @log = @karfunkel.log
      end
      
      #Main method to handle a client. This method loops and calls
      #the different request handling methods depending on what the
      #client sends. It ends when the client sends EOF or an error occurs.
      def handle_connection(client)
        #Loop and execute a client's requests.
        #Each command is separated by the NULL character.
        while str = client.socket.gets("\0")
          #Check wheather it conforms to Karfunkel's command standards.
          #If so, get the XML object.
          xml = parse_command(str)
          #Now process each request in the command.
          xml.root.children.each do |request_node|
            #Get command type and ID
            type = request_node['type']
            id = request_node["id"]
            
            #The requests are assumed to be methods of this module.
            #In a specific format of course, otherwise somebody could
            #try to send an instance_eval request or something bad like that.
            sym = :"process_#{type}_request"
            if respond_to?(sym, true) #The request methods are private
              #Transform the XML request into a parameters hash, i.e. each
              #child node is interpreted as a hash key and the node's text is
              #assigned as the value.
              hsh = request_node.children.inject({}){|h, node| h[node.name] = node.text}
              send(sym, id, hsh)
            else
              reject(client, type, id, "Unknown request type.")
            end #if
          end #each child
        end #while requests are in the command
      end #handle_connection
      
      #This method tries to establish a connection between Karfunkel
      #and a possible client.
      def establish_connection(client)
        #Wait for the client to greet
        unless select([client.socket], nil, nil, GREET_TIMEOUT)
          raise(ConnectionFailed, "No greeting from client.")
        end
        #OK, the client has sent some data. Check it.
        begin
          xml = parse_command(client.socket.gets("\0").strip, true)
        rescue => e #The first command MUST be completely valid - nuke otherwise.
          raise(ConnectionFailed, "Error while parsing command: #{e.message}")
        end
        #Get the first request--the greeting should contain just this single request
        request = xml.root.children[0]
        #This must be a HELLO request
        unless request["type"] == "Hello"
          raise(ConnectionFailed, "Request was not a HELLO request.")
        end
        #If we get here, the command is a valid greeting.
        #Here one could add authentication, but for now we accept the
        #request as OK.
        client.os = request.children.at_xpath("os")
        greet_back(client)
      end
      
      private
      
      #Sends a response of type +Rejected+.
      def reject(client, command_type, command_id, reason)
        
      end
      
      #===============================================
      #These are the request processing methods.
      
      def process_open_project_request(command_id, parameters)
        
      end
      
      #===============================================
      #Some helper methods follow.
      
      #Karfunkel's positive answer to a HELLO request.
      def greet_back(client)
        builder = Nokogiri::XML::Builder.new do |xml|
          xml.Karfunkel(:id => KARFUNKEL_ID) do
            xml.response(:type => "Hello", :id => 0) do
              xml.status OK
              xml.id_ ID_GENERATOR.next
              xml.my_version VERSION
              #xml.my_project ...
              xml.my_clients_num @karfunkel.clients.size
            end
          end
        end
        client.socket.write(builder.to_xml + "\0")
      end
      
      #Checks wheather or not +str+ is a valid Karfunkel command
      #and raises a MalformedCommand error otherwise. If all went well,
      #a Nokogiri::XML::Document is returned.
      def parse_command(str, dont_check_id = false)
        xml = Nokogiri::XML(str, nil, nil, 0) #Raise an error on invalid document
        raise(MalformedCommand, "Root node is not 'Karfunkel'.") unless xml.root.name == "Karfunkel"
        raise(MalformedCommand, "No or invalid client ID given.") if !dont_check_id and xml.root["id"] != "0"
        return xml
      rescue Nokogiri::XML::SyntaxError
        raise(MalformedCommand, "Malformed XML document.")
      end
      
    end
    
  end
  
end
