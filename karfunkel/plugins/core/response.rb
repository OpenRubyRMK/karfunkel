# -*- coding: utf-8 -*-

#Responses are delivered as reactions on requests (see the Core::Request class).
#They’re parts of a Core::Command, you cannot deliver standalone responses.
#
#The most important place where it comes to responses is inside the
#Request classes when calling the +answer+ method. This method takes
#as it’s first argument a symbol determining the response type; this
#may in fact be any symbol you like (except :error, which is used
#internally), but most of the time you’ll find yourself using these
#response symbols:
#[ok]          Everything went well.
#[:rejected]   You don’t want to process the request.
#[:processing] You started processing the request, but it’ll take some
#              time to complete.
#[:finished]   A long-running request processing completed.
#[:failed]     A long-running request processing failed.
#For each of these responses (except :ok maybe) you should pass some
#information along with the +answer+ call, e.g. you should put a
#<tt>:reason</tt> if you <tt>:rejected</tt> someone, i.e.
#  answer :rejected, :reason => "I don’t like you."
class OpenRubyRMK::Karfunkel::Plugins::Core::Response
  
  #This response’s type. One of the symbols mentioned in this class’s
  #documentation.
  attr_accessor :status
  #(Hopfully) useful pieces of information as a hash (the keys are
  #strings).
  attr_reader :attributes
  #The Request object this response is a reaction to. This can be +nil+
  #in the case of an :error response.
  attr_reader :request
  #The Core::Client object in charge for sending the response, i.e.
  #where the response comes *from*. To get the Core::Client object
  #describing the original _request_ sender, use
  #<tt>resp.request.sender</tt>.
  attr_reader :sender
  
  #Creates a new Response. 
  #==Parameters
  #[sender]          The Core::Client object this response comes *from*.
  #[request]         The request you want to answer. If you’re deliving an
  #                  :error response you can set this to +nil+, because an
  #                  :error response usually is the result of sending malformed
  #                  or otherwise damaged XML from which you cannot derive a
  #                  Core::Request object.
  #[status]          (:ok) This response’s status. See this class’ documentation
  #                  for a list of possible symbols.
  #[attributes] ({}) Further attributes you want to attach to your response.
  #                  Keys will show up as tag names, values as their, well, values.
  #==Return value
  #The newly created instance.
  #==Example
  #  resp = OpenRubyRMK::Karfunkel::Response.new(a_client,
  #                                              a_request,
  #                                              :rejected,
  #                                              :reason => "I don't like you")
  def initialize(sender, request, status = :ok, attributes = {})
    raise(ArgumentError, "No request given!") if !request and status != :error
    @sender = sender
    @request = request
    @request.responses << self if @request
    @attributes = attributes
    @status = status
  end
  
  #Grabs an attribute.
  #==Parameter
  #[attribute] The attribute to read. Autoconverted to a string by #to_s.
  #==Return value
  #Either the attribute or nil if it can’t be found.
  def [](attribute)
    @attributes[attribute.to_s]
  end
  
  #Sets an attribute.
  #==Parameters
  #[attribute] The attribute to set. Autoconverted to a string by #to_s.
  #[value]     The value to assign. Autoconverted to a string by #to_s.
  def []=(attribute, value)
    @attributes[attribute] = value
  end
  
  #Returns the request’s ID or -1 if no request was set for an :error
  #response. Note this is, as everything else, a string.
  def id
    if @request
      @request.id
    else #For the :error response
      "-1"
    end
  end
  
  #Returns the request’s type or an empty string if no request was
  #set for an :error response.
  def type
    if @request
      @request.type
    else #For the :error response
      ""
    end
  end
  
  #Human-readable description of form
  #  #<OpenRubyRMK::Karfunkel::Plugins::Core::Response <type>|<status>, attributes: <attrs>>
  #.
  def inspect
    "#<#{self.class} #{type}|#@status, attributes: #{@attributes.inspect}>"
  end
  
  #call-seq:
  #  == other      → true or false
  #  eql?( other ) → true or false
  #
  #Two responses are considered equal if they refer to the
  #same request.
  def ==(other)
    @request == other.request
  end
  alias eql? ==
  
end
