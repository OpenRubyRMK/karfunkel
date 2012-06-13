# -*- coding: utf-8 -*-

module OpenRubyRMK::Common

  #A command is the container for requests (class Request), responses
  #(class Response) and notifications (class Notification) and every
  #communication with the OpenRubyRMK’s server Karfunke is done
  #through them. Their external representation is a XML structure which
  #is fully defined in the commands_and_responses.rdoc and
  #the {requests}[link:server_requests.html] file.
  #
  #Note that it is possible to construct commands that may map to
  #valid XML, but aren’t understandable by Karfunkel. Call the #valid?
  #method in order to find out if your command conforms to the
  #communication guidelines.
  class Command
    include Comparable

    #The byte marking the end of an XML command.
    END_OF_COMMAND = 0x00
    
    #The ID of the client that sent the command.
    attr_reader :from_id
    #All requests that this command contains.
    attr_accessor :requests
    #All responses that this command contains.
    attr_accessor :responses
    #All notifications that this command contains.
    attr_accessor :notifications

    #Creates a new and blank command.
    #==Parameter
    #[from_id] The ID of the client that this command
    #          is sent from. If you want to deliver a
    #          +Hello+ request, be sure to set this to -1
    #          because you haven’t been assigned an ID yet.
    #==Return value
    #The newly created instance.
    def initialize(from_id)
      @from_id       = from_id
      @requests      = []
      @responses     = []
      @notifications = []
    end

    #Human-readable description of form:
    #  #<OpenRubyRMK::Common::Command by ID <id>>
    def inspect
      "#<#{self.class} by ID #@from_id>"
    end

    #True if this command doesn’t contain any requests,
    #responses or notifications.
    def empty?
      @requests.empty? && @responses.empty? && @notifications.empty?
    end

    #Appends information to the command.
    #==Parameter
    #[obj] A Request, Response or Notification instance that will be
    #      appended to the proper attribute array.
    #==Raises
    #[ArgumentError] You passed something other than an instance of
    #                Request, Response or Notification.
    #==Return value
    #This method returns +self+, so you can easily chain
    #method calls.
    #==Examples
    #  cmd << Request.new(11, 3, "foo") << Response.new(3, "bar")
    def <<(obj)
      case obj
      when Request      then @requests      << obj
      when Response     then @responses     << obj
      when Notification then @notifications << obj
      else
        raise(ArgumentError, "Don't know what to do with #{obj.inspect}!")
      end

      self
    end

    #The total number of requests, responses and notifications
    #contained in this request. The <sender> block isn’t counted
    #by this method.
    #==Return value
    #Some integer value greater than or equal to zero.
    def size
      @requests.count + @responses.count + @notifications.count
    end

    #Compares two commands. The comparison is based on
    #the #size method, but if two commands have the same size, it’s
    #checked whether they refer to the actual same subobjects (see
    #the Response, Request and Notification classes’ documentation for
    #when two of the respective objects are considered equal). If they
    #don’t the two commands are declared non-comparable and nil is
    #returned.
    def <=>(other)
      return nil unless [:size, :requests, :responses, :notifications].all?{|sym| other.respond_to?(sym)} # Convention for non-comparable things
      
      if size == other.size
        if @requests == other.requests && @responses == other.responses && @notifications == other.notifications
          0
        else
          nil # Convention for non-comparable objects
        end
      else
        size <=> other.size
      end
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
