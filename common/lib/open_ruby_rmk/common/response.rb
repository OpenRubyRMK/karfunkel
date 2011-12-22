module OpenRubyRMK::Common

  class Response

    attr_reader :id
    attr_reader :request
    attr_accessor :parameters

    def initialize(id, request)
      @id          = id
      @request     = request
      @parameters  = {}
    end

    def [](par)
      @parameters[par.to_s]
    end

    def []=(par, value)
      @parameters[par.to_s] = value.to_s
    end
    
    def type
      if @request
        @request.type
      else
        "error" # If no request has been defined, this must be an :error response
      end
    end

    def eql?(other)
      return false if !@request or !other.request # For the :error response
      @request == other.request
    end

    def inspect
      "#<#{self.class} #{type.upcase}>"
    end

  end

end
