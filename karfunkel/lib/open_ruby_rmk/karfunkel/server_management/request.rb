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
  #    #These are the parameters the Foo request accepts. Required
  #    #parameters will cause an exception if they’re not passed
  #    #before your #execute method (see below) is called.
  #    parameter :x
  #    #Create optional parameter as shown below. If they aren’t
  #    #passed, the default value is automatically merged into
  #    #the parameters hash for your #execute method (see below).
  #    optional_parameter :y, 0
  #
  #    #This method will be called when Karfunkel receives your
  #    #request. It gets passed all required and optional parameters
  #    #and their values as a hash of form {"par" => "val"}. Note
  #    #that optional parameters if they haven’t been passed are
  #    #automatically set to their default value.
  #    def execute(pars)
  #      # Grab the parameters passed and do the real coding.
  #      result = pars[:x].to_i + pars[:y].to_i
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
  #    #to a client and now received a response from the client.
  #    def process_response(resp)
  #      Karfunkel.log_info("[#{resp.sender}] Client answered #{response[:result]}.")
  #    end
  #
  #  end
  #
  #=== XML
  #Please don’t forget that all communication between the server and
  #it’s clients happens in XML format. While this shouldn’t bother
  #you for the most cases, it playes an important role for parameters
  #and their values: XML doesn’t know about "numbers" or "objects".
  #In XML, there are just strings, and that’s the reason why your
  #parameters hash will be composed entirely of strings--the parameters
  #as well as the values. In the above code, it’s the reason why
  #we need to call the #to_i method on our parameter values in order
  #to add them mathematically together.
  #
  #=== Accessing the sender
  #
  #If you need to access the object describing the sender of the request
  #for some reason, you can do so via the instance variable <tt>@sender</tt>.
  #It contains an instance of class OpenRubyRMK::Karfunkel::ServerManagement::Client.
  #
  #Inside the #process_response method, <tt>@sender</tt> points still
  #to the *same* client as in #execute--that is, the sender of the
  #original request. To access the sender of the response, use
  #the response’s <tt>sender</tt> method.
  #
  #=== Exceptions
  #You’re free to raise any exception you like in the +execute+ and
  #+process_response+ methods, but you should stick to those defined inside
  #the OpenRubyRMK::Karfunkel::Errors module, especially the +InvalidParameter+
  #exception for indicating that you encountered an incorrect
  #parameter, e.g.
  #
  #  def execute(pars)
  #    raise(Errors::InvalidParameter, "X too large!") if pars[:x].to_i > 10_000
  #    #...
  #  end
  class Request
        
    #For simpler typing
    Karfunkel = OpenRubyRMK::Karfunkel::SM::Karfunkel
    #For simpler typing
    Errors = OpenRubyRMK::Errors
    #For simpler typing
    PM = OpenRubyRMK::Karfunkel::PM
    
    #Parameters for a request. They’re set when the XML is loaded
    #from a file; this is a hash of form
    #  {:parameter => "value"}
    attr_reader :parameters
    #The ID of this request.
    attr_reader :id
    #The Responses corresponding to this request.
    attr_accessor :responses
    
    #Creates a new Request. You should only instanciate subclasses of this
    #class, otherwise this is a senseless object. Pass in the ID of
    #the request.
    def initialize(sender, id)
      @id = id.to_s
      @sender = sender
      @parameters = {}
      @responses = []
    end
    
    #Returns the value of a parameter.
    def [](par)
      par = par.to_s #This way it works for symbols, too
      raise(ArgumentError, "Not a valid parameter: #{par}!") unless self.class.valid_parameter?(par)

      #Try to get a set value
      return @parameters[par] if @parameters.keys.include?(par)
      #OK, fallback to the optional one
      self.class.optional_parameters[par]
    end
    
    #Sets the value of a parameter. Should only be used when loading the
    #XML files.
    def []=(par, value)
      raise(ArgumentError, "Not a valid parameter: #{par}!") unless self.class.valid_parameter?(par)
      @parameters[par.to_s] = value.to_s
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

    #Merges all optional and required parameters and then
    #passes them as a single hash to #execute, which should
    #have been defined inside the Request DSL.
    #==Raises
    #[ArgumentError] A required parameter has not been set on the request.
    def execute!
      self.class.parameters.each do |required|
        unless @parameters[required]
          raise(ArgumentError, "Required parameter '#{required}' not given!")
        end
      end
      execute(self.class.optional_parameters.merge(@parameters))
    end


    
    #Two requests are considered equal if they have the same ID.
    def eql?(other)
      @id == other.id
    end
    alias == eql?
    
    #Checks wheather or not we already received a response for this request.
    def running?
      @responses.empty?
    end

    #Part of the Request DSL--override this method in your request
    #to execute the actual request code.
    #==Parameters
    #[parameters] A hash containing all parameters for this request,
    #             optional parameters with their default values
    #             as necessary as well as required parameters. You
    #             can access the parameters as well via the internal
    #             instance variables @parameters and @optional_parameters,
    #             but we recommend using the +parameters+ hash as it
    #             eases your processing.
    #==Return value
    #Uninteresting.
    def execute(parameters)
      raise(NotImplementedError, "#{__method__} must be overriden in a subclass!")
    end

    #Part of the Request DSL--override this method in your request
    #to execute the actual response code.
    def process_response(response)
      raise(NotImplementedError, "#{__method__} must be overriden in a subclass!")
    end
    
    private
    
    #Part of the Request DSL -- tells the request processor to create
    #a Response with the given values. The respose is not sent immediately,
    #but scheduled to be sent when Karfunkel finished processing all requests
    #of the current command.
    #Example:
    #  def execute
    #    #Do some coding...
    #    answer :ok, :some_info => "Something"
    #  end
    def answer(sym, hsh = {})
      @sender.response(Response.new(Karfunkel, self, sym, hsh)) #This sends a response TO the requestor
    end
    
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
    def broadcast(type, attributes)
      Karfunkel.add_broadcast(Notification.new(Karfunkel, type, attributes))
    end

    class << self
      public
      
      #Part of the Request DSL -- tells the request definer that we want to
      #define a new request type.
      def define(type, &block)
        Requests.const_set(type, Class.new(self, &block))
      end

      #The names of all parameters required for this request.
      #An array of strings.
      def parameters
        @parameters ||= []
      end

      #The names and default values of all optional parameters
      #for this request. A hash of form:
      #  "parname" => "fallback"
      def optional_parameters
        @optional_parameters ||= {}
      end
      
      #Checks wheather or not +str+ is a valid parameter
      #for this request, i.e. defined as a required or optional
      #parameter name.
      #==Parameter
      #[str] The symbolic name of the parameter to check.
      #==Return value
      #Either true or false
      def valid_parameter?(str)
        str = str.to_s #This way it works for symbols, too
        parameters.include?(str) || optional_parameters.keys.include?(str)
      end
      
      private
      
      #Part of the Request DSL -- adds a required parameter.
      def parameter(str)
        parameters << str.to_s #This way it works for symbols, too
      end

      #Part of the Request DSL -- adds an optional parameter with
      #a default value (which defaults to an empty string). 
      def optional_parameter(str, opt_val = "")
        optional_parameters[str.to_s] = opt_val.to_s #XML can only contain strings
      end      
      
    end
    
  end
  
end
