module OpenRubyRMK::Common

  class Response

    attr_reader :id
    attr_reader :status
    attr_reader :request
    attr_accessor :parameters

    def initialize(id, status, request)
      @id          = id
      @status      = status
      @request     = request
      @parameters  = {}
    end

    def [](par)
      @parameters[par.to_s]
    end

    def []=(par, value)
      @parameters[par.to_s] = value.to_s
    end

    def mapped?
      !!@request
    end

    def eql?(other)
      return false if !@request or !other.request # For the :error response
      @request == other.request
    end

    def inspect
      "#<#{self.class} #{request.type.upcase}:#{@status}>"
    end

  end

end
