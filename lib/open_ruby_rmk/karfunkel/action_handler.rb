# -*- coding: utf-8 -*-

#Special class encapsulating the context request and
#response handlers run in. The attributes of an instance
#of this class are set only temporarily (apart from the
#handled type and actual handler code, of course, which
#are set by the user in his plugin file), allowing the
#block passed to the Plugin::process_request and
#Plugin::process_response methods to easier access the
#Request, Response and Client instances they’re concerned
#with.
#
#The methods most interesting for you as a plugin writer
#are the protected methods documented further below. Additionally,
#this class includes the OpenRubyRMK::Karfunkel::Plugin::Helpers
#module, allowing you to use the generic helper methods defined
#there in your handler code blocks.
class OpenRubyRMK::Karfunkel::ActionHandler
  include OpenRubyRMK::Karfunkel::Plugin::Helpers

  #The currently handled Request instance.
  attr_reader :request
  #The currently handled Response instance (nil if none).
  attr_reader :response
  #The client whose data we’re currently processing.
  attr_reader :client
  #The handler code as a code block (Proc object).
  attr_reader :handler
  #The request type this handler can handle. This is a
  #string, to ease comparison with what requests and
  #responses return.
  attr_reader :type

  ##
  # :method: rejected
  #call-seq:
  #  rejected(client, request, hsh)
  #
  #Like #ok, but for the +rejected+ status.

  ##
  # :method: error
  #call-seq:
  #  error(client, request, hsh)
  #
  #Like #ok, but for the +error+ status.

  ##
  # :method: ok
  #call-seq:
  #  ok(client, request, hsh)
  #
  #Delivers the +ok+ response.
  #==Parameters
  #[client] The client to deliver to.
  #[request] The request to answer.
  #[hsh]     Any information you want to include into the response
  #          as a hash (both keys and values will be converted
  #          to string on delivering).

  ##
  # :method: processing
  #call-seq:
  #  processing(client, request, hsh)
  #
  #Like #ok, but for the +processing+ status.

  ##
  # :method: failed
  #call-seq:
  #  failed(client, request, hsh)
  #
  #Like #ok, but for the +failed+ status.

  ##
  # :method: finished
  #call-seq:
  #  finished(client, request, hsh)
  #
  #Like #ok, but for the +finished+ status.

  #Creates a new instance of this class. Pass the block
  #that is to be used as the request/response handler.
  def initialize(type, &block)
    @type    = type.to_s
    @handler = block
  end

  def call(client, request, response = nil)
    # Make the Client, Request and Response instances
    # available to the process_* block. Inside the block,
    # the user can either refer to e.g. @request directly
    # or use the accessor method #request (without knowing
    # it, presumly).
    @client   = client
    @request  = request
    @response = response
    instance_eval(&@handler)
  ensure
    # Ensure to unset these variables even if the exection
    # of the block terminates with an exception. Otherwise
    # confusing relicts may be left (e.g. if you inspect
    # the ActionHandler instance and see a Request instance
    # assigned although no request is currently being
    # processed).
    @client   = nil
    @request  = nil
    @response = nil
  end

  protected

  #Answers the currently running request.
  #==Parameters
  #[status] The request status, i.e. one of :ok, :rejected,
  #         :processing, :failed and :finished.
  #[hsh]    Any information you want to include into the
  #         response as a hash (both keys and values will
  #         be converted to strings upon delivering).
  def answer(status, hsh = {})
    if respond_to?(status, true)
      send(status, hsh)
    else
      raise(NoMethodError, "Unknown answer method '#{status}'!")
    end
  end

  [:rejected, :error, :ok, :processing, :failed, :finished].each do |sym|
    define_method(sym) do |hsh = {}|
      res = OpenRubyRMK::Common::Response.new(OpenRubyRMK::Karfunkel.instance.generate_request_id, sym, @request)
      hsh.each_pair{|k, v| res[k] = v}
      OpenRubyRMK::Karfunkel.instance.deliver_response(res, @client)
    end
  end

end
