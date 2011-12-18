module OpenRubyRMK::Common

  class Notifications

    attr_reader :from_id
    attr_reader :id
    attr_accessor :parameters

    def initialize(from_id, id)
      @from_id    = id
      @id         = id
      @parameters = {}
    end

    def [](par)
      @parameters[par.to_s] || raise(KeyError, "Parameter not found: #{par}!")
    end

    def []=(par, value)
      @parameters[par.to_s] = value.to_s
    end
    
  end

end
