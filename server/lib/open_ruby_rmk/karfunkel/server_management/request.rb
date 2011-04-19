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
  #The files in that directory are simple Ruby files containing the
  #request type’s definition in a simple DSL (Domain specific language). To
  #define a new request type, let’s say +Foo+, create a file *foo.rb* in
  #the above directory and put this in it:
  #
  #  OpenRubyRMK::Karfunkel::SM::Request.define :Foo do
  #
  #    #These are the parameters the Foo request accepts
  #    attribute :x
  #    attribute :y
  #
  #    #This method gets called when a request of your type is
  #    #encountered. It gets passed the Client that made the request.
  #    def execute(client)
  #      #Grab the parameters passed and do the real coding.
  #      #Note you must access the parameters using self[:parameter],
  #      #bcecause no instance variables are set for this.
  #      result = self[:x].to_i + self[:y].to_i
  #      #When you’re done, end with one of the possible responses
  #      #(see the Response class for a list of possible symbols).
  #      #The answer method takes the response type and a hash whose
  #      #keys and values will be used to create the respective XML
  #      #tags of the response.
  #      answer :ok, :result => result
  #    end
  #
  #  end
  class Request
    
    #For simpler typing
    Karfunkel = OpenRubyRMK::Karfunkel::SM::Karfunkel
    
    #Parameters for a request. They’re set when the XML is loaded
    #from a file; this is a hash of form
    #  {:parameter => "value"}
    attr_reader :attributes
    #The ID of this request.
    attr_reader :id
    
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
      Requests.const_set(:"#{type.capitalize}Request", Class.new(self, &block))
    end
    
    #Creates a new Request. You should only instanciate subclasses of this
    #class, otherwise this is a senseless object. Pass in the ID of
    #the request.
    def initialize(id)
      @id = id.to_s
      @attributes = {}
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
    def execute(client)
      raise(NotImplementedError, "This method must be overriden in a subclass!")
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
    def answer(sym, hsh = {})
      Response.new(self, sym, hsh)
    end
    
  end
  
end