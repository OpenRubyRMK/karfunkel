#!/usr/bin/env ruby
#Encoding: UTF-8

module OpenRubyRMK
  
  module Karfunkel
    
    #This is a mixin module mixed into the connections made to
    #Karfunkel. The public methods are called by EventMachine,
    #the private ones are helper methods.
    #
    #Whenever the user sent a complete command, #process_command
    #is triggered which instantiates an instance of one of the
    #classes in the Requests module.
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
        #If the client doesn't authenticate within 5 seconds, disband
        #him.
        EventMachine.add_timer(Karfunkel.config[:greet_timeout]) do
          if @client.available? and !@client.authenticated?
            Karfunkel.log_warn("Connection timeout for #{@client}.")
            terminate!
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
          @received_data.clear
        end
      end
      
      #Called by EventMachine when this connection has been
      #closed.
      def unbind
        Karfunkel.clients.delete(@client)
        Karfunkel.log_info("Connection to #{@client} closed.")
      end
      
      private
      
      #===============================================
      #Some helper methods follow.
      
      #Processes a command and instantiates the appropriate
      #command classes, which in turn instantiate and deliver
      #the (hopefully) correct response classes. Exception are
      #the +error+ response which is issued on malformed commands
      #and the entire processing of the +hello+ request, which are
      #done inside this method and some helper methods.
      def process_command(command)
        #If the client has not authenticated yet, we have to do so.
        unless @client.authenticated?
          if authenticate(command)
            @client.authenticated = true
            Karfunkel.log_debug("Client #{@client} authenticated.")
            greet_back
            Karfunkel.log_info("Client #{@client} connected.")
          else
            Karfunkel.log_warn("Authentication failed for #{@client}!")
            terminate!
          end
        else
          #Check wheather it conforms to Karfunkel's command standards.
          #If so, get the XML object.
          xml = parse_command(command)
          #Now process each request in the command.
          xml.root.children.each do |request_node|
            #Get command type and ID
            type = request_node['type']
            id = request_node["id"]
            
            #The requests are assumed to be classes of the Requests module.
            #In a specific format of course, otherwise somebody could
            #try to send a Kernel request or something bad like that.
            sym = :"#{type}Request"
            if Requests.const_defined?(sym)
              Karfunkel.log_debug("[#{@client}] Request: #{type}")
              #Transform the XML request into a parameters hash, i.e. each
              #child node is interpreted as a hash key and the node's text is
              #assigned as the value.
              hsh = request_node.children.inject({}){|h, node| h[node.name] = node.text; h}
              
              @client.requests << Requests.const_get(sym).new(@client, id, hsh)
              @client.requests.last.start
            else
              Karfunkel.log_warn("[#{@client}] Invalid request #{type}")
              Responses::RejectResponse.new(self, "Unknown request type.").deliver!
            end #if
          end #each child
        end #unless authenticated
      rescue Errors::ConnectionFailed => e #Non-Recoverable--connection immediately cut.
        Karfunkel.log_error("Fatal connection error with client #{client}:")
        Karfunkel.log_exception(e)
        terminate!
      rescue => e
        Karfunkel.log_warn("Ignoring error with client #{client}: ")
        Karfunkel.log_exception(e, :warn)
        error(client, "Unable to process request: #{e.class.name}: #{e.message}")
      end #process_request
      
      #Tries to authenticate the connection by processing
      #+request+. Returns true if everything worked out,
      #false otherwise.
      def authenticate(request)
        xml = parse_command(request, true) #Raises MalformedCommand if fed invalid XML
        request = xml.root.children[0]
        #This must be a HELLO request
        unless request["type"] == "Hello"
          raise(Errors::ConnectionFailed, "Request was not a HELLO request.")
        end
        #If we get here, the command is a valid greeting.
        #Here one could add authentication, but for now we accept the
        #request as OK.
        new_id = Karfunkel.generate_id
        @client.id = new_id
        @client.os = request.children.at_xpath("os")
        true
      rescue => e
        Karfunkel.log_error("Error on initial connection with #{@client}!")
        Karfunkel.log_exception(e)
        false
      end
      
      #Karfunkel's positive answer to a HELLO request.
      def greet_back
        builder = Nokogiri::XML::Builder.new(encoding: "UTF-8") do |xml|
          xml.Karfunkel(:id => Karfunkel::ID) do
            xml.response(:type => "Hello", :id => 0) do
              xml.status "ok"
              xml.id_ @client.id
              xml.my_version VERSION
              #xml.my_project ...
              xml.my_clients_num Karfunkel.clients.size
            end
          end
        end
        send_data(builder.to_xml + END_OF_COMMAND)
      end
      
      #Sends an error response.
      def error(client, str)
        builder = Nokogiri::XML::Builder.new(encoding: "UTF-8") do |xml|
          xml.Karfunkel(:id => Karfunkel::ID) do
            xml.response(:type => "unknown", :id => -1) do
              xml.status "error"
              xml.message str
            end
          end
        end
        send_data(builder.to_xml + END_OF_COMMAND)
      end
      
      #Checks wheather or not +str+ is a valid Karfunkel command
      #and raises a MalformedCommand error otherwise. If all went well,
      #a Nokogiri::XML::Document is returned.
      def parse_command(str, dont_check_id = false)
        #Make Nokogiri only parsing valid XML and removing blank nodes, i.e.
        #text nodes with whitespace only.
        xml = Nokogiri::XML(str, nil, nil, Nokogiri::XML::ParseOptions::STRICT | Nokogiri::XML::ParseOptions::NOBLANKS)
        raise(Errors::MalformedCommand, "Root node is not 'Karfunkel'.") unless xml.root.name == "Karfunkel"
        raise(Errors::MalformedCommand, "No or invalid client ID given.") if !dont_check_id and xml.root["id"] == Karfunkel::ID.to_s
        return xml
      rescue Nokogiri::XML::SyntaxError
        raise(Errors::MalformedCommand, "Malformed XML document.")
      end
      
      #Immediately cuts the connection to Karfunkel,
      #setting the client's availability status to false.
      def terminate!
        close_connection
        @client.available = false
      end
      
    end
    
  end
  
end
