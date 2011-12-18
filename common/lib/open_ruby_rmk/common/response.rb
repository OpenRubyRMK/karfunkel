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
      @parameters[par.to_s] || raise(KeyError, "Parameter not found: #{par}!")
    end

    def []=(par, value)
      @parameters[par.to_s] = value.to_s
    end
    
    def type
      @request.type
    end

  end

end
