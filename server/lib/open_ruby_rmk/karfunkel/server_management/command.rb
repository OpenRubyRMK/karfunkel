#!/usr/bin/env ruby
#Encoding: UTF-8

module OpenRubyRMK
  
  module Karfunkel
    
    module ServerManagement
      
      #A command containg requests and/or responses that shell be
      #send to a client sometime.
      class Command
        
        #The sender of this command.
        attr_reader :sender
        #The requests contained in this command. An array.
        attr_accessor :requests
        #The responses contained in this command. An array.
        attr_accessor :responses
        
        #"Reverse-engineers" a Command object from an XML string (or
        #Nokogiri::XML::Node object). If you're absolutely sure which
        #client sent the command, you may pass the Client object as +client+,
        #which makes this method skip the step of trying to figure it out from
        #the Karfunkel.clients array (this is a quite performance-intensive
        #operation).
        def self.from_xml(xml, client = nil)
          command_node = xml.kind_of?(Nokogiri::XML::Node) ? xml : parse_command(xml).root
          
          sender = client ? client : Karfunkel.clients.find{|item| item.id == command_node.at_xpath("sender/id").to_i}
          
          obj = new(sender)
                    
          obj.requests = command_node.xpath("request").map do |request_node|
            type = request_node["type"]
            id = request_node["id"]
            #The requests are assumed to be classes of the Requests module.
            #In a specific format of course, otherwise somebody could
            #try to send a Kernel request or something bad like that.
            sym = :"#{type}Request"
            if Requests.const_defined?(sym)
              Requests.const_get(sym).from_xml(request_node)
            else
              raise(RequestNotFound.new("No such request: #{sym}!", sym, id))
            end
          end
          obj.responses = command_node.xpath("responses").map do |response_node|
            id = response_node["id"]
            type = response_node["type"]
            #Same procedure as for requests
            sym = :"#{type}Response"
            if Responses.const_defined?(sym)
              Responses.const_get(sym).from_xml(response_node)
            else
              raise(ResponseNotFound.new("No such response: #{sym}!", sym, id))
            end
          end
          
          obj
        end
        
        #Creates a new Command. Pass in the sender (which is a Client
        #object).
        def initialize(sender)
          @sender = sender
          @requests = []
          @responses = []
          #@events = []
        end
        
        #Adds +obj+, which must either be a Request or a Response object,
        #to the command. Raises a TypeError if you try to add something
        #else to the command.
        def <<(obj)
          case obj
          when Requests::Request then @requests << obj
          when Responses::Response then @responses << obj
          else
            raise(TypeError, "Doesn't know how to put a #{obj.class} into a command.")
          end
        end
        
        #Returns true if this command doesn't contain anything useful that
        #is worth to be devilred, i.e. no requests and no responses.
        def empty?
          @requests.empty? and @responses.empty?
        end
        
        #Returns the Nokogiri::XML::Builder describing the XML needed
        #to produce the XML string of this command. The ! inidicates that
        #this method will change the +parent_node+ argument if you pass
        #a Nokogiri::XML::Node object (which is then of course used
        #as the parent for the XML created here).
        def build_xml!(parent_node = nil)
          #Ever wanted to pass the same block to 2 different methods?
          #Ruby's great^^
          l = lambda do |xml|
            xml.Karfunkel do
              xml.sender do
                xml.id_ @sender.id
              end
              @requests.each{|request| request.build_xml!(xml.doc.children.first)}
              @responses.each{|response| response.build_xml!(xml.doc.children.first)}
            end
          end
          
          if parent_node
            Nokogiri::XML::Builder.with(parent_node, &l)
          else
            Nokogiri::XML::Builder.new(encoding: "UTF-8", &l)
          end
        end
        
        #Same as #build_xml!, but without the possibility of a parent node.
        def build_xml
          build_xml!
        end
        
        #Delivers this command to +clients+, which must be Client objects.
        def deliver!(*clients)
          raise(ArgumentError, "No client specified!") if clients.empty?
          
          cmd = build_xml.to_xml + Protocol::END_OF_COMMAND
          clients.each do |client|
            raise(RuntimeError, "Karfunkel can't send himself commands.") if client == Karfunkel
            client.connection.send_data(cmd)
          end
        end
        
        private
        
        #Checks wheather or not +str+ is a valid Karfunkel command
        #and raises a MalformedCommand error otherwise. If all went well,
        #a Nokogiri::XML::Document is returned.
        def self.parse_command(str, dont_check_id = false)
          #Make Nokogiri only parsing valid XML and removing blank nodes, i.e.
          #text nodes with whitespace only.
          xml = Nokogiri::XML(str, nil, nil, Nokogiri::XML::ParseOptions::STRICT | Nokogiri::XML::ParseOptions::NOBLANKS)
          raise(Errors::MalformedCommand, "Root node is not 'Karfunkel'.") unless xml.root.name == "Karfunkel"
          #raise(Errors::MalformedCommand, "No or invalid client ID given.") if !dont_check_id and xml.root["id"] == Karfunkel::ID.to_s
          return xml
        rescue Nokogiri::XML::SyntaxError
          raise(Errors::MalformedCommand, "Malformed XML document.")
        end
        
      end
      
    end
    
  end
  
end