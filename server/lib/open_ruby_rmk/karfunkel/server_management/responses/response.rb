#!/usr/bin/env ruby
#Encoding: UTF-8

module OpenRubyRMK
  
  module Karfunkel
    
    module ServerManagement
    
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
          
          attr_reader :request_id
          attr_reader :type
          
          #Some extra key-value pairs you want to include in your response.
          #They will show up as
          #  <key>value</key>
          #inside the RESPONSE tag. Don't use keys for tag names already
          #used by the response type you use, because that may cause
          #confusion on the client side.
          attr_accessor :info
          
          def self.from_xml(xml)
            response_node = xml.kind_of?(Nokogiri::XML::Node) ? xml : parse_response(xml)
            
            new(response_node["id"], response_node["type"])
          end
          
          #Instantiates an object of this response. Nothing is sent here,
          #but you should define new parameters to get all the necessary
          #information for your request object. Don't forget to call
          #+super+ with the first argument passed to ::new.
          def initialize(request_id, type)
            @request_id = request_id
            @type = type
            @alive = true
            @info = {}
          end
          
          #Returns wheather or not we still need this response object.
          def alive?
            @alive
          end
          
          #Returns the type of this response by looking at the class name,
          #i.e. a class named +OKResponse+ will have a type of "ok". A
          #class named +FooResponse+ will have a type of "foo". The return
          #value is always a downcased string.
          def status
            self.class.name.split("::").last.match(/Response$/).pre_match.downcase
          end
          alias to_s status
          
          def build_xml!(parent_node = nil)
            l = lambda do |xml|
              xml.response(:id => @request_id, :type => @type.to_s) do #@type may be a symbol
                xml.status status
                make_xml(xml)
                #Now render the extra information
                @info.each_pair{|k, v| xml.send(k, v)}
              end
            end
            
            if parent_node
              Nokogiri::XML::Builder.with(parent_node, &l)
            else #Shouldn't be necessary because the resulting XML is not a valid Karfunkel command
              Nokogiri::XML::Builder.new(encoding: "UTF-8", &l)
            end
          end
          
          def build_xml
            build_xml!
          end
          
          #call-seq:
          #  eql?( other ) → true or false
          #  self == other → true or false
          #
          #Compares two requests. They're considered equal if they both
          #have the same request ID.
          def eql?(other)
            @request_id == other.request_id
          end
          alias == eql?
          
          private
          
          def self.parse_response(str)
            xml = Nokogiri::XML(str, nil, nil, Nokogiri::XML::ParseOptions::STRICT | Nokogiri::XML::ParseOptions::NOBLANKS)
          rescue Nokogiri::XML::SyntaxError
            raise(Errors::MalformedCommand, "Malformed XML document.")
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
          def make_xml(xml)
            raise(NotImplementedError, "#{__method__} has to be overriden in a subclass!")
          end
          
        end
        
      end
      
    end
    
  end
  
end
