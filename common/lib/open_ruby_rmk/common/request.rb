module OpenRubyRMK::Common

  class Request
    
    attr_reader :from_id
    attr_reader :id
    attr_reader :type
    attr_reader :responses
    attr_accessor :parameters

    def initialize(from_id, id, type)
      @from_id    = from_id
      @id         = id
      @type       = type
      @parameters = {}
      @responses  = []
    end

    def [](par)
      @parameters[par.to_s]
    end

    def []=(par, value)
      @parameters[par.to_s] = value.to_s
    end

    def eql?(other)
      @id == other.id
    end
    alias == eql?

    def running?
      @responses.empty?
    end

    def inspect
      "<#{self.class} #{@type.upcase}>"
    end

  end

end
