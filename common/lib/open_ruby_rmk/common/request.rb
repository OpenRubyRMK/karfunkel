module OpenRubyRMK::Common

  class Request
    
    attr_reader :from_id
    attr_reader :id
    attr_reader :type
    attr_reader :response_ids
    attr_accessor :parameters

    def initialize(from_id, id, type)
      @from_id      = from_id
      @id           = id
      @type         = type
      @parameters   = {}
      @response_ids = []
    end

    def [](par)
      @parameters[par.to_s] || raise(KeyError, "Parameter not found: #{par}!")
    end

    def []=(par, value)
      @parameters[par.to_s] = value.to_s
    end
    
  end

end
