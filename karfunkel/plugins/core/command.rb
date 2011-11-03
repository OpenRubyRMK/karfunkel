# -*- coding: utf-8 -*-

#A command is the container for responses (class Core::Response),
#requests (class Core::Request) and notifications (class Core::Notification), 
#and every communication #with the OpenRubyRMK server Karfunkel is done with them. 
#Their external representation is a XML structure which is fully defined in the
#commands_and_responses.rdoc and the {requests}[link:server_requests.html] file.
#
#This is one of the classes you should pay some attention to if you want to
#write a client for the server. You don’t have to understand the whole thing,
#but it may come in handy if you have an idea on how the server processes
#your requests and responses.
class OpenRubyRMK::Karfunkel::Plugins::Core::Command
  
  #The Core::Client that sent the command.
  attr_reader :from
  #An array of instances of Core::Request subclasses. These are all the
  #requests contained in this command.
  attr_accessor :requests
  #An array of Core::Response objects. These are all the responses contained
  #in this command.
  attr_accessor :responses
  #An array of Core::Notification objects. These are all the notificactions
  #contained in this command.
  attr_accessor :notifications
  
  #Loads a command from the XML representation, including all the contained
  #requests and responses.
  #===Parameters
  #[str]  The XML string.
  #[from] The Core::Client object from which this command was sent.
  #===Raises
  #[MalformedCommand] On XML syntax errors and an incorrect root element.
  #[RequestNotFound]  Invalid request type found.
  def self.from_xml(str, from)
    begin
      doc = Nokogiri::XML(str, nil, nil, Nokogiri::XML::ParseOptions::STRICT | Nokogiri::XML::ParseOptions::NOBLANKS)
    rescue Nokogiri::SyntaxError => e
      raise(OpenRubyRMK::Errors::MalformedCommand, e.message)
    end
    raise(OpenRubyRMK::Errors::MalformedCommand, "Root node not Karfunkel!") unless doc.root.name == "Karfunkel"
    #I don’t check for the <sender> block, because a HELLO request doesn’t have
    #such a tag. Just the #to_xml method will crash if the client doesn’t get
    #an ID assigned, because it calls the original client’s #id method.
    
    cmd = new(from)
    
    #Responses
    doc.root.xpath("response").each do |node|
      request = from.sent_requests.find{|req| req.id == node["id"]}
      resp = OpenRubyRMK::Karfunkel::Plugins::Core::Response.new(from, request)
      
      resp.status = node["status"]
      
      node.children.each do |child_node|
        res[child_node.name] = child_node.text
      end
      cmd.responses << resp
    end
    
    #Requests
    doc.root.xpath("request").each do |node|
      raise(OpenRubyRMK::Errors::RequestNotFound.new(node["type"], node["id"]), "No such request: '#{node['type']}'!") unless OpenRubyRMK::Karfunkel::Plugins::Core::Request::Requests.const_defined?(node["type"])
      request = OpenRubyRMK::Karfunkel::Plugins::Core::Request::Requests.const_get(node["type"]).new(from, node["id"])
      
      node.children.each do |child_node|
        request[child_node.name] = child_node.text
      end
      
      cmd.requests << request
    end
    
    #Notifications
    #This is for completeness, it’s the server who sends notifications,
    #not some clients. One could even send a REJECT response to
    #a client sending a notification. See the Notification#sender
    #attribute for some explanation.
    doc.root.xpath("notification").each do |node|
      note = OpenRubyRMK::Karfunkel::Plugins::Core::Notification.new(from, node["type"])
      node.children.each do |child_node|
        note[child_node.name] = child_node.text
      end
      cmd.notifications << note
    end
    
    #Return value
    cmd
  end
  
  #Creates a new and blank command.
  #===Parameters
  #[from] The Core::Client object this command shell be send *from*. Where
  #       it goes *to* is specified as an argument to the #deliver! method.
  def initialize(from)
    @from = from
    @requests = []
    @responses = []
    @notifications = []
  end
  
  #Checks wheather or not any requests, responses or notifications 
  #have been defined for this command.
  #===Example
  #  OpenRubyRMK::Karfunkel::Command.new(OpenRubyRMK::Karfunkel::THE_INSTANCE).empty? #=> true
  #  c = OpenRubyRMK::Karfunkel::Command.new(OpenRubyRMK::Karfunkel::THE_INSTANCE)
  #  c.responses << OpenRubyRMK::Karfunkel::Response.new(a_request, a_request.id, :ok)
  #  e.empty? #=> false
  def empty?
    @requests.empty? and @responses.empty? and @notifications.empty?
  end
  
  #This build the XML tree that can be delivered over the wire. The resulting
  #format is described in the commands_and_responses.rdoc file.
  #===Return value
  #A string containing the XML.
  def to_xml
    builder = Nokogiri::XML::Builder.new(encoding: "UTF-8") do |xml|
      xml.Karfunkel do #The root element
        
        #Build the <sender> block
        xml.sender do
          xml.id_ @from.id
        end
        
        #Process all responses and build <response> blocks
        @responses.each do |response|
          xml.response(:type => response.type, :id => response.id, :status => response.status) do
            response.attributes.each_pair do |key, value|
              xml.send(key, value.to_s) #to_s allows for arbitrary values in the attribute
            end
          end
        end
        
        #Process all requests and build <request> blocks
        @requests.each do |request|
          xml.request(:type => request.type, :id => request.id) do
            request.parameters.each_pair do |key, value|
              xml.send(key, value.to_s) #to_s allows for arbitrary values in the attribute
            end
          end
        end
        
        #Process all the notifications and build <notification> blocks
        @notifications.each do |note|
          xml.notification(:type => note.type) do
            note.attributes.each_pair do |key, value|
              xml.send(key, value.to_s) #to_s allows for arbitrary values in the attribute
            end
          end
        end
      end
    end
    builder.to_xml
  end
  
  #Delivers this command to the given client. Ensure that +to_client+’s
  #+connection+ is valid.
  #===Parameters
  #[to_client] The Core::Client where to send the command to.
  def deliver!(to_client)
    to_client.connection.send_data(to_xml + OpenRubyRMK::Karfunkel::Plugins::Core::Protocol::END_OF_COMMAND)
  end
  
end
