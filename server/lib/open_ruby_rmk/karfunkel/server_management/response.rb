#Encoding: UTF-8

module OpenRubyRMK::Karfunkel::SM
  
  #Responses are delivered as reactions on requests (see the Request class).
  #They’re parts of a Command, you cannot deliver standalone responses.
  #
  #The most important place where it comes to responses is inside the
  #Request classes when calling the +answer+ method. This method takes
  #as it’s first argument a symbol determining the response type; this
  #may in fact be any symbol you like (except :error, which is used
  #internally), but most of the time you’ll find yourself using these
  #response symbols:
  #[ok]          Everything went well.
  #[:rejected]   You don’t want to process the request.
  #[:processing] You started processing the request, but it’ll take some
  #              time to complete.
  #[:finished]   A long-running request processing completed.
  #[:failed]     A long-running request processing failed.
  #For each of these responses (except :ok maybe) you should pass some
  #information along with the +answer+ call, e.g. you should put a
  #<tt>:reason</tt> if you <tt>:rejected</tt> someone, i.e.
  #  answer :rejected, :reason => "I don’t like you."
  class Response
    
    #This response’s type. One of the symbols mentioned in this class’s
    #documentation.
    attr_accessor :status
    #(Hopfully) useful pieces of information as a hash (the keys are
    #strings).
    attr_reader :attributes
    #The Request object this response is a reaction to. This can be +nil+
    #in the case of an :error response.
    attr_reader :request
    
    #Creates a new Response. Pass in the Request you react to (you can
    #only pass +nil+ if you’re constructing an error response, because this
    #response may be a result of malformed XML where you can’t construct a
    #Request object), the requests +status+ (see this class’s documentation
    #for a list of possible symbols) and the attributes of this response.
    def initialize(request, status = :ok, attributes = {})
      raise(ArgumentError, "No request given!") if !request and status != :error
      @request = request
      @request.responses << self if @request
      @attributes = attributes
      @status = status
    end
    
    #Grabs the specified +attribute+ which should be a string.
    def [](attribute)
      @attributes[attribute]
    end
    
    #Sets the spcified +attribute+. Both the +attribute+ and the +value+
    #should be strings.
    def []=(attribute, value)
      @attributes[attribute] = value
    end
    
    #Returns the request’s ID or -1 if no request was set for an :error
    #response.
    def id
      if @request
        @request.id
      else #For the :error response
        "-1"
      end
    end
    
    #Returns the request’s type or an empty string if no request was
    #set for an :error response.
    def type
      if @request
        @request.type
      else #For the :error response
        ""
      end
    end
    
    #call-seq:
    #  == other      → true or false
    #  eql?( other ) → true or false
    #
    #Two responses are considered equal if they refer to the
    #same request.
    def ==(other)
      @request == other.request
    end
    alias eql? ==
    
  end
  
end
