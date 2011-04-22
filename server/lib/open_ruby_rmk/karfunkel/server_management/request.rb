#Encoding: UTF-8

module OpenRubyRMK::Karfunkel::SM
  
  #This module is used to store the request classes
  module Requests
  end
  
  #A request is the part of the Command that instructs the other
  #end of the connection to take action. A command may contain multiple
  #requests or none at all, but if it does, the requests’s structure must
  #be defined by one of the subclasses of this class. They all reside
  #in the Requests module, and are loaded dynamically from the
  #*lib/open_ruby_rmk/karfunkel/server_management/requests* directory.
  #
  #== Defining new request types
  #
  #The files in that directory are simple Ruby files containing the
  #request type’s definition in a simple DSL (Domain specific language). To
  #define a new request type, let’s say +Foo+, create a file *foo.rb* in
  #the above directory and put this in it:
  #
  #  #This line tells the processor to define a request type called "Foo"
  #  OpenRubyRMK::Karfunkel::SM::Request.define :Foo do
  #
  #    #These are the parameters the Foo request accepts
  #    attribute :x
  #    attribute :y
  #
  #    #This method gets called when a request of your type is
  #    #encountered. It gets passed the Client that made the request.
  #    def execute(client)
  #      # Grab the parameters passed and do the real coding.
  #      # Note you must access the parameters using self[:parameter],
  #      # bcecause no instance variables are set for this.
  #      result = self[:x].to_i + self[:y].to_i
  #      # If you feel the need you have to notify all currently connected
  #      # clients on your actions, call #broadcast and attach some
  #      # valuable information.
  #      broadcast :map_loading, :percent => 35
  #      # When you’re done, end with one of the possible responses
  #      # (see the Response class for a list of possible symbols).
  #      # The answer method takes the response type and a hash whose
  #      # keys and values will be used to create the respective XML
  #      # tags of the response.
  #      answer :ok, :result => result
  #    end
  #
  #    #This method gets called when Karfunkel sent a request of your type
  #    #to a client and now received a response from the client. +client+ is
  #    #the client sending the response and +response+ is the Response
  #    #object.
  #    def process_response(client, response)
  #      Karfunkel.log_info("[#{client}] Client answered #{response[:result]}.")
  #    end
  #
  #  end
  #
  #== Exceptions
  #
  #You’re free to raise any exception you like in the +execute+ and
  #+process_response+ methods, but you should stick to those defined inside
  #the OpenRubyRMK::Karfunkel::Errors module, especially the +InvalidParameter+
  #exception for indicating that you encountered a missing or incorrect
  #parameter, e.g.
  #
  #  def execute(client)
  #    raise(Errors::InvalidParameter, "X not given!") unless self[:x]
  #    #...
  #  end
  class Request
    
    class DSL
      
      #For simpler typing
      Karfunkel = OpenRubyRMK::Karfunkel::SM::Karfunkel
      #For simpler typing
      Errors = OpenRubyRMK::Karfunkel::Errors
      #For simpler typing
      PM = OpenRubyRMK::Karfunkel::PM
      
      def initialize(type, &block)
        #These variables catch information for the new request class
        @attribute_names = []
        @execute_block = nil
        @process_response_block = nil
        
        #This executes the DSL
        instance_eval(&block)
        
        #These create the new request class with all the facilities defined
        #by the DSL.
        klass = Class.new(Request)
        klass.instance_variable_set(:"@attribute_names", @attribute_names) #Yes, this is a class instance variable
        klass.send(:define_method, :execute, &@execute_block) if @execute_block
        klass.send(:define_method, :process_response, &@process_response_block) if @response_block
        Requests.const_set(:"#{type.capitalize}Request", klass)
      end
      
      private
      
      def attribute(sym)
        @attribute_names << sym
      end
      
      def execute(&block)
        @execute_block = block
      end
      
      def process_response(&block)
        @execute_block = block
      end
      
      def answer(sym, hsh)
        #TODO: Send answer
      end
      
      def broadcast(sym, hsh)
        Karfunkel.add_broadcast(Notification.new(type, attributes))
      end
      
    end
    
    #Parameters for a request. They’re set when the XML is loaded
    #from a file; this is a hash of form
    #  {:parameter => "value"}
    attr_reader :attributes
    #The ID of this request.
    attr_reader :id
    #The response corresponding to this request or nil if there wasn’t
    #a response yet.
    attr_accessor :response
    
    #Part of the Request DSL -- tells the request definer that +name+
    #is a parameter of this request. +name+ should be a symbol.
    def self.attribute(name)
      valid_attribute_names << name.to_s
    end
    
    #Returns a list of all possible attributes/parameter sof this request class.
    def self.valid_attribute_names
      @attribute_names ||= []
    end
    
    #Checks wheather or not +attribute+ is a possible parameter of
    #this request class.
    def self.valid_attribute?(attribute)
      valid_attribute_names.include?(attribute)
    end
    
    #Part of the Request DSL -- tells the request definer that we want to
    #define a new request type.
    def self.define(type, &block)
      DSL.new(type, &block)
    end
    
    #Creates a new Request. You should only instanciate subclasses of this
    #class, otherwise this is a senseless object. Pass in the ID of
    #the request.
    def initialize(id)
      @id = id.to_s
      @attributes = {}
      @response = nil
    end
    
    #Returns the value of a parameter.
    def [](attribute)
      raise(ArgumentError, "Not a valid attribute: #{attribute}!") unless self.class.valid_attribute?(attribute)
      @attributes[attribute]
    end
    
    #Sets the value of a parameter. Should only be used when loading the
    #XML files.
    def []=(attribute, value)
      raise(ArgumentError, "Not a valid attribute: #{attribute}!") unless self.class.valid_attribute?(attribute)
      @attributes[attribute] = value
    end
    
    #This request’s type. It’s determined from the class name.
    def type
      self.class.name.split("::").last.sub(/Request$/, "")
    end
    
    #Human-readable description of form
    #  #<OpenRubyRMK::Karfunkel::ServerManagement::Request ID=<id>>
    def inspect
      "#<#{self.class} ID=#{id}>"
    end
    
    #Part of the request DSL. You must override this method in your own
    #request types; it’s called whenever Karfunkel comes over a request
    #of your type. +client+ is the Client that made the request.
    def execute!(client)
      raise(NotImplementedError, "This method must be overriden in a subclass!")
    end
    
    #Part of the request DSL. You must override this method in your own
    #request types; it’s called whenever Karfunkel detects an answer to
    #a request of this type. +response+ is the Response object representing
    #the response--this is however just for making the DSL more readable, you
    #could as well use the @response instance variable which should contain
    #the same Response. If not, you found a bug.
    def process_response(response)
      raise(NotImplementedError, "This method must be overriden in a subclass!")
    end
    
    #Two requests are considered equal if they have the same ID.
    def eql?(other)
      @id == other.id
    end
    alias == eql?
    
    #Checks wheather or not we already received a response for this request.
    def running?
      @response.nil?
    end
    
    private
    
    #Part of the Request DSL -- tells the request processor to create
    #a Response with the given values. The respose is not sent immediately,
    #but scheduled to be sent when Karfunkel finished processing all requests
    #of the current command.
    #Example:
    #  def execute(client)
    #    #Do some coding...
    #    answer :ok, :some_info => "Something"
    #  end
    #def answer(sym, hsh = {})
    #  @response = Response.new(self, sym, hsh)
    #end
    
    #Part of the Request DSL -- remembers a Notification object you
    #define by the +type+ (which is used to distinguish notifications
    #for e.g. easier translations) and the attributes. No restrictions
    #exist for neither +type+ nor +attributes+, but you should document
    #what broadcasts your request type tends to deliver.
    #Example:
    #  def execute(client)
    #    #Do some coding...
    #    broadcast :foo, :message => "This is foo!"
    #    #Further coding...
    #  end
    #def broadcast(type, attributes)
    #  Karfunkel.add_broadcast(Notification.new(type, attributes))
    #end
    
  end
  
end