# -*- coding: utf-8 -*-

module OpenRubyRMK::Common

  #Responses are delivered as reactions to requests (see the Request
  #class). They’re part of a Command instance and as such externally
  #represented as an XML structure. Their opening tag is RESPONSE.
  #
  #Responses may contain parameters the same way requests do.
  #This allows for a detailed response to be sent back to the client.
  #
  #Where a Request instance has a +type+ attribute indicating
  #which type of request this is, responses offer an attribute
  #called +status+ that informs you which type of response your’re
  #dealing with. Although it is possible to design responses with
  #any type of status, Karfunkel itself only uses the following six
  #statuses:
  #[ok] Everythig went well.
  #[rejected] Your request was rejested for some reason.
  #           See the response’s parameters for more
  #           information.
  #[processing] Your request is being processed, but has not finished
  #             yet. Look out for the FINISHED response. This response
  #             may be sent multiple times during processing.
  #[finished]   A long-running request has been completed.
  #[failed]     A long-running request failed to complete. See
  #             the parameters for more information.
  #[error]      You either send invalid XML or a request Karfunkel doesn’t
  #             understand.
  #
  #In order to map the response to some kind of Request object,
  #you have to pass the corresponding Request to the ::new method.
  #From the XML view of things, this is represented with the
  #ANSWERS attribute of the RESPONSE node (see below for an example).
  #== Sample XML
  #=== With parameters
  #  <response id="4" status="rejected" answers="324">
  #    <reason>I don't like you</reason>
  #  </response>
  #=== Without parameters
  #  <response id="12" status="ok" answers="5"/>
  class Response

    #A (hopefully) unique ID.
    attr_reader :id
    #This response’s status as a *string* as it comes directly from the XML.
    attr_reader :status
    #The request this response answers. An ERROR response however might
    #not have this, especially in the case of invalid XML.
    attr_reader :request
    #The response’s parameters as a hash where both the keys and values
    #are strings as they’re directly read from the XML.
    attr_accessor :parameters

    #Creates a new instance of this class.
    #==Parameters
    #[id] A unique ID for this response.
    #[status]  One of the statuses explained in the class docs.
    #          Automatically converted to a string by calling #to_s.
    #[request] The request you want to answer with this response.
    #          If you want to construct a ERROR response without
    #          a corresponding Request instance, you have to
    #          explicitely pass +nil+ here.
    #==Return value
    #The brand new Response object.
    #==Example
    #  req = Request.new(3, "ok", myreq)
    #  req = Request.new(33, "processing", myreq)
    #  req = Request.new(333, "error", nil)
    def initialize(id, status, request)
      @id          = id
      @status      = status.to_s
      @request     = request
      @parameters  = {}
    end

    #Grabs the specified parameter.
    #==Parameter
    #[par] The name of the parameter you want to read.
    #      Automatically converted to a string by #to_s.
    #==Return value
    #The value of the parameter as a string.
    #==Example
    #  resp = Response.new(1, "processing", myreq)
    #  resp["foo"] = "bar"
    #  resp[:abc]  = 33
    #   
    #  resp["foo"] #=> "bar"
    #  resp[:foo]  #=> "bar"
    #  resp[:abc]  #=> "33"
    #  resp["abc"] #=> "33"
    def [](par)
      @parameters[par.to_s]
    end

    #Sets the specified parameter.
    #==Parameters
    #[par]   The name of the parameter you want to set.
    #        This isn’t checked in the context of your
    #        request, so be careful when setting this.
    #        Autoconverted to a string by calling #to_s.
    #[value] The value of your parameter. Autonconverted
    #        to a string by calling #to_s.
    #==Return value
    #Exactly +value+ as the Ruby interpreter enforces this.
    #==Example
    #  resp = Response.new(1, "processing", myreq)
    #  resp["foo"] = "bar"
    #  resp[:abc]  = 33
    #   
    #  resp["foo"] #=> "bar"
    #  resp[:foo]  #=> "bar"
    #  resp[:abc]  #=> "33"
    #  resp["abc"] #=> "33"
    def []=(par, value)
      @parameters[par.to_s] = value.to_s
    end

    #Checks if your response belongs to a request.
    #This should only evaluate to true for some
    #ERROR responses.
    def mapped?
      !!@request
    end

    #call-seq:
    #  eql?(other)   → bool
    #  self == other → bool
    #
    #Checks whether or not two responses are equal. Two responses
    #are considered equal if they belong to the same request
    #and have the same ID and status.
    def eql?(other)
      return nil unless other.respond_to? :id
      @request == other.request && @id == other.id && # Works even when @request is nil (for the :error response)
        @status == other.status
    end
    alias == eql?

    #Human-readable description of form:
    #  <OpenRubyRMK::Common::Response <REQUEST_TYPE>:<response status>>
    def inspect
      "#<#{self.class} #{request.type.upcase}:#{@status}>"
    end

  end

end
