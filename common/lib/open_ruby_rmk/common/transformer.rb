# -*- coding: utf-8 -*-

module OpenRubyRMK::Common

  #Main class for handling XML markup. Any valid Karfunkel-style XML
  #can be turned into a Command instance and vice-versa by means of
  #this class. Pass your commands’ bunches of XML to the #parse! method
  #one at a time and you’ll be provided with one Command instance each.
  #The #convert! method allows you to turn your Command instances into
  #send-ready XML markup.
  #
  #==About the internal state
  #Never use different transformer instances for the same connection. If
  #you do, you will run into all kinds of confusing effects, because
  #internally, the transformer keeps track of some information that needs
  #to be preserved between parser runs. For example, the transformer
  #remembers any requests you tranform into their XML representation
  #in order to connect them to their response. That is, if you send
  #an +Eval+ request to Karfunkel and you transform it into XML
  #by means of this class, it remembers the Request instance.
  #Then, when Karfunkel answers, it takes the response and
  #fills its +request+ attribute with the Request instance it previously
  #remembered.
  #
  #However, if you _really_ need to use different Transformer instances
  #for your connection, you should ensure the #clean? method returns
  #true. If so, the transformer’s internal state is clean and it’s
  #safe to exchange the instance with some other. Transformers that
  #have just been created and haven’t yet been used are always clean.
  class Transformer

    #List of requests that have been sent, but didn’t receive
    #a response yet. An array of Request objects.
    attr_reader :waiting_requests

    #Creates a new instance.
    def initialize
      @waiting_requests = []
    end

    #Takes a string of Karfunkel XML markup and parses it.
    #==Parameter
    #[xml] A string containing XML.
    #==Raises
    #[Errors::MalformedCommand] You passed something that either isn’t
    #                           valid XML or doesn’t conform to the
    #                           Command conventions.
    #==Return value
    #This method returns an instance of the Command class that
    #has been filled with any sub-entities that have been found
    #in the XML markup, i.e. if it contained any requests,
    #you will find them inside the commands +requests+ array.
    #==Example
    #  cmd = parser.parse!(str)
    #  cmd.requests.count              #=> 3
    #  cmd.responses.count             #=> 1
    #  cmd.reponses.first.request.type #=> "Eval"
    #==Remarks
    #If the parser detects a response to a nonexisting request,
    #the response will be silently discarded instead of being
    #added to the command’s +responses+ array. This however
    #causes a warning to be emmited on $stderr.
    def parse!(xml)
      begin
        doc = Nokogiri::XML(xml, nil, nil, Nokogiri::XML::ParseOptions::STRICT | Nokogiri::XML::ParseOptions::NOBLANKS)
      rescue Nokogiri::SyntaxError => e
        raise(Errors::MalformedCommand, e.message)
      end
      
      sender_node = doc.at("karfunkel/sender/id") # Missing if this command contains the HELLO request
      sender_id   = sender_node ? sender_node.content.to_i : -1
      cmd         = Command.new(sender_id)

      # Requests
      doc.root.xpath("request").each do |node|
        request = Request.new(sender_id, node["id"].to_i, node["type"])

        # Parameters
        node.children.each do |child|
          request[child.name] = child.content
        end

        cmd.requests << request
      end

      # Responses
      doc.root.xpath("response").each do |node|
        id      = node["id"].to_i
        req_id  = node["answers"].to_i
        request = @waiting_requests.find{|req| req.id == req_id} # May be nil if a client sends an unwanted response!
        warn("Skipping unmappable response with ID #{id}.") and next unless request # TODO: ERROR response doesn’t answer anything
        
        # Create the Response object and establish the dual-sided
        # relationship of a request and its response
        response = Response.new(id, request)
        request.responses << response

        # If the request has completed, delete it from the list of
        # outstanding requests.
        @waiting_requests.delete(request) if node["type"] == "ok" or node["type"] == "finished"
        
        # Parameters
        node.children.each do |child|
          response[child.name] = child.content
        end

        cmd.responses << response
      end

      # Notifications
      doc.root.xpath("notification").each do |node|
        note = Notification.new(sender_id, node["id"].to_i)

        # Parameters
        node.children.each do |child|
          note[child.name] = child.content
        end

        cmd.notifications << note
      end

      # Check wheather we constructed something useful
      raise(Errors::MalformedCommand, "Command doesn't conform to the guidelines!") unless cmd.valid?

      cmd
    end

    # Takes a Command instance and turns it into its XML representation.
    #==Parameter
    #[cmd] The command instance.
    #==Raises
    #[Errors::MalformedCommand] Some impossible request/response combination
    #                           was requested by the command.
    #==Return value
    #A UTF-8 encoded string of XML.
    #==Example
    #  cmd = Command.new(3) # Sender ID 3
    #  cmd.requests << Request.new(3, 1, "Foo")
    #  trans.convert!(cmd)
    def convert!(cmd)
      # Check wheather the user constructed something useful
      raise(Errors::MalformedCommand, "Command doesn't conform to the guidelines!") unless cmd.valid?

      builder = Nokogiri::XML::Builder.new(encoding: "UTF-8") do |xml|
        xml.karfunkel do # The root element
          unless cmd.from_id == -1
            # Build the <sender> block (except when +from_id+ is -1,
            # which is the case for commands containing the HELLO request)
            xml.sender do
              xml.id_ cmd.from_id
            end
          end
          
          # Requests
          cmd.requests.each do |request|
            @waiting_requests << request # Remember we’re waiting for a response
            
            xml.request(type: request.type, id: request.id) do
              request.parameters.each{|par, val| xml.send(par, val)}
            end
          end

          # Responses
          cmd.responses.each do |response|
            xml.response(type: response.request.type, id: request.id, status: response.status) do
              response.parameters.each{|par, val| xml.send(par, val)}
            end
          end

          # Notifications
          cmd.notifications.each do |note|
            xml.notification(type: note.type) do
              note.parameters.each{|par, val| xml.send(par, val)}
            end
          end

        end # <karfunkel>
      end # Builder.new

      builder.to_xml
    end # convert!

    #This is true if the transformer’s internal state
    #is clean, i.e. it could be exchanged with another Transformer
    #instance without causing any harm.
    #==Return value
    #True or false.
    #==Example
    #  # Setup
    #  trans1 = Transformer.new
    #  trans2 = Transformer.new
    #  trans1.clean? #=> true
    #  
    #  # Make a request to some other client
    #  cmd = Command.new(11)
    #  req = Request.new(11, 3, "foo")
    #  cmd.requests << req
    #  trans1.convert!
    #  trans1.clean? #=> false
    #  
    #  # Client processes the response and answers
    #  cmd = Command.new(12)
    #  cmd.responses << Response.new(1, req)
    #  xml = trans2.convert!(cmd)
    #  
    #  # Receive the response
    #  trans1.parse!(xml)
    #  trans1.clean? #=> true
    def clean?
      @waiting_requests.empty?
    end
    
    #Human-readable description of form:
    #  <OpenRubyRMK::Common::Transformer <clean or not clean>>
    def inspect
      "#<#{self.class} #{clean? ? 'clean' : 'not clean'}>"
    end

  end

end
