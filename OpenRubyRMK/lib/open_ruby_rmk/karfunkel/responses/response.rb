#!/usr/bin/env ruby
#Encoding: UTF-8

module OpenRubyRMK
  
  module Karfunkel
    
    module Responses
      
      #This is the superclass of all responses Karfunkel might send
      #(except +error+, because it's somewhat non-standard). It
      #implements everything that is common across all responses and
      #deligates response-specific things, namely the main part of the
      #XML body, to the subclasses of this class. Look at the OKResponse
      #for a simple example on how to build a response class.
      #
      #Oh, and note you *must* name your subclasses +FooResponse+, where
      #+Foo+ is the type of your response. This is necessary, because
      #the automatic XML creation procedure will determine the
      #value of the +type+ attribute by looking at the class' name. If you
      #really don't want to name your class like that, you have to override
      ##to_s and return a downcased string representing the type. That string
      #will directly be incorporated into the XML response.
      class Response
        
        #Instantiates an object of this response. Nothing is sent here,
        #but you should define new parameters to get all the necessary
        #information for your request object. Don't forget to call
        #+super+ with the first argument passed to ::new.
        def initialize(request)
          @request = request
        end
        
        #Returns the type of this response by looking at the class name,
        #i.e. a class named +OKResponse+ will have a type of "ok". A
        #class named +FooResponse+ will have a type of "foo". The return
        #value is always a downcased string.
        def to_s
          self.class.name.split("::").last.match(/Response$/).pre_match.downcase
        end
        
        #This method builds the main body of the XML response. It is
        #called by #send_response and gets passed a Nokogiri::XML::Builder
        #object which you have to use to build up the response. You don't
        #have to return anything from this method.
        #
        #Building the XML is as easy as
        #  def build_xml(xml)
        #    xml.yourtag "tag_content"
        #    xml.another_tag "another_tags_content"
        #  end
        #You don't have to care about all the command stuff that must be
        #placed around this response essence--#send_response takes care
        #about that for you.
        def build_xml(xml)
          raise(NotImplementedError, "#{__method__} has to be overriden in a subclass!")
        end
        
        #Called immediately before the command containing the response is
        #sent to the client. Does nothing by default.
        def pre_deliver
        end
        
        #Called immediately after the command containing the response is
        #sent to the client. Does nothing by default.
        def post_deliver
        end
        
        #Delivers this response to the client.
        def deliver!
          #First we build the general form of a response...
          builder = Nokogiri::XML::Builder.new(encoding: "UTF-8") do |xml|
            xml.Karfunkel(:id => Karfunkel::ID) do
              xml.response(:type => @request.to_s, :id => @request.request_id) do
                xml.status self.to_s
                #...then we deligate the response-specific details to the
                #subclasses.
                build_xml(xml)
              end
            end
          end
          command = builder.to_xml + Protocol::END_OF_COMMAND
          
          #Now send the command to the client.
          pre_deliver
          @request.client.connection.send_data(command)
          post_deliver
        end
        
      end
      
    end
    
  end
  
end
