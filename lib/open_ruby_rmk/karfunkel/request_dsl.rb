#The domain specific language used for defining request
#and response handlers (i.e. the methods available inside
#the blocks passed to +process_request+ and +process_response+).
#This module is intended to only be mixed into ActionHandler
#and exists solely for having a single central place of
#defining the methods of the DSL.
#If you absolutely must include this mixin, you have to
#provide a +request+ method that returns the currently
#active Common::Request instance (or +nil+ if none), a
#+response+ method that returns the currently active
#Common::Response instance and a +client+ method that
#returns the Client object the data is sent to.
module OpenRubyRMK::Karfunkel::RequestDSL

  protected

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

  #Answers the currently running request.
  #==Parameters
  #[status] The request status, i.e. one of :ok, :rejected,
  #         :processing, :failed and :finished.
  #[hsh]    Any information you want to include into the
  #         response as a hash (both keys and values will
  #         be converted to strings upon delivery).
  def answer(status, hsh = {})
    if respond_to?(status, true)
      send(status, hsh)
    else
      raise(NoMethodError, "Unknown answer method '#{status}'!")
    end
  end

  [:rejected, :error, :ok, :processing, :failed, :finished].each do |sym|
    define_method(sym) do |hsh = {}|
      res = OpenRubyRMK::Common::Response.new(OpenRubyRMK::Karfunkel.instance.generate_request_id, sym, request)
      hsh.each_pair{|k, v| res[k] = v}
      OpenRubyRMK::Karfunkel.instance.deliver_response(res, client)
    end
  end

  #Delivers a notification to all currently connected clients.
  #==Parameters
  #[type] The notification type. You can use your own types,
  #       but please document them.
  #       FIXME: And what are the built-in types?
  #[hsh]  ({}) Any information you want to include into the
  #       notification as a hash (both keys and values will
  #       be converted to strings upon delivery).
  def broadcast(type, hsh = {})
    note = OpenRubyRMK::Common::Notification.new(OpenRubyRMK::Karfunkel.instance.generate_request_id, type)
    hsh.each_pair{|k, v| note[k] = v}
    OpenRubyRMK::Karfunkel.instance.deliver_notification(note)
  end

  #Marks the specified parameter as optional, i.e. if the client
  #did not set it, return a default value instead of rejecting the
  #request when requesting that parameter from the Request instance.
  #==Parameters
  #[parameter_name] The parameter you want to optionalise.
  #                 Automatically converted to a string.
  #[default_value]  ("") The default value you want to
  #                 be returned if the parameter is missing.
  #                 Automatically converted to a string.
  def optional(parameter_name, default_value = "")
    request.add_default_value(parameter_name, default_value)  if request
    response.add_default_value(parameter_name, default_value) if response
  end

end
