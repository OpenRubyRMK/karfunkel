# -*- coding: utf-8 -*-

module OpenRubyRMK::Common

  class Command
    include Comparable
    
    attr_reader :from_id
    attr_accessor :requests
    attr_accessor :responses
    attr_accessor :notifications

    def initialize(from_id)
      @from_id       = from_id
      @requests      = []
      @responses     = []
      @notifications = []
    end

    def inspect
      "#<#{self.class} by ID #@from_id>"
    end

    def empty?
      @requests.empty? && @responses.empty? && @notifications.empty?
    end

    def <<(obj)
      case obj
      when Request      then @requests      << obj
      when Response     then @responses     << obj
      when Notification then @notifications << obj
      else
        raise(ArgumentError, "Don't know what to do with #{obj.inspect}!")
      end
    end

    def eql?(other)
      @requests == other.requests &&
        @responses == other.responses &&
        @notifications == other.notifications
    rescue NoMethodError
      nil # Convention for non-comparable things
    end
    alias == eql?

    def size
      @requests.count + @responses.count + @notifications.count
    end

    def <=>(other)
      return nil unless other.respond_to?(:size) # Convention for non-comparable things
      size <=> other.size
    end

    #Checks wheather the command conforms to the Karfunkel
    #XML guidelines, and if so, returns true. Most notably
    #this method is to check for valid commands containing
    #a +Hello+ request.
    def valid?
      if @requests.any?{|req| req.type == "Hello"}
        case
        when @requests.count > 1 then false
        when @from_id != -1      then false
        else
          true
        end
      else # Contains no HELLO request
        !empty? # Empty commands don’t make sense
      end
    end

  end
end
