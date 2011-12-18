module OpenRubyRMK::Common

  class Command
    
    attr_reader :from_id
    attr_accessor :requests
    attr_accessor :responses

    def initialize(from_id)
      @from_id   = from_id
      @requests  = []
      @responses = []
    end

  end
end
