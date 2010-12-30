#!/usr/bin/env ruby
#Encoding: UTF-8

module OpenRubyRMK
  
  module Karfunkel
    
    #This class solely exists, because I didn't want to mess up karfunkel.rb
    #with all the commands the Karfunkel server understands. Every command
    #is represanted as a method implemented for this class.
    class Controller
      
      GREET_TIMEOUT = 5
      ID_GENERATOR = (1..Float::INFINITY).enum_for(:each)
      
      #Creates a new Controller for the given Karfunkel instance.
      def initialize(karfunkel)
        @karfunkel = karfunkel
        @log = @karfunkel.log
        @next_id
      end
      
      def handle_connection(client)
        #Execute the obligatory greeting code
        return false unless establish_connection
        
        #Now loop and execute a client's requests.
        #Each command is separated by the NULL character.
        while str = client.socket.gets("\0")
          #Check wheather it conforms to Karfunkel's command standards.
          #If so, get the XML object.
          xml = check_syntax(str)
          unless xml
            @log.error("Connection error with client #{client}: Malformed command. Ignoring the issue.")
            next
          end
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
      
      def greeting(client)
        str = client.socket.gets("\0").strip
        
        if !syntax_check(str, true)
          @log.error("Connection with client #{client} failed: Malformed command.")
          return false
        elsif request["type"] != "Hello"
          @log.error("Connection with client #{client} failed: Not a HELLO request.")
          return false
        end
        
        xml = Nokogiri::XML(str)
        request = xml.root.children[0]
        client.os = request.children.at_xpath("os")
        true
      end
      
      #This method tries to establish a connection between Karfunkel
      #and a possible client.
      def establish_connection(client)
        unless select([client.socket], nil, nil, GREET_TIMEOUT)
          @log.error("Connection with client #{client} failed: No greeting from client.")
          return false
        end
        return false unless greeting(client)
        true
      end
      
      def syntax_check(str, dont_check_id = false)
        xml = Nokogiri::XML(str)
        return false unless xml.root.name == "Karfunkel"
        return false if !dont_check_id and xml.root["id"] != "0"
        return xml
      rescue #Most likely, the XML document was invalid if an exception occures.
        return false
      end
      
    end
    
  end
  
end
