# -*- coding: utf-8 -*-

#Extensions to bare Karfunkel’s plugin module that add many useful
#methods regarding the networking process. This module is one of
#the main reasons why you shouldn’t remove the +Core+ plugin from
#your Karfukel configuration--many other plugins will break if the
#extensions defined by this module are not available.
#
#This module is (via monkeypatch) mixed into OpenRubyRMK::Karfunkel::Plugin
#when the +Core+ plugin is activated.
module OpenRubyRMK::Karfunkel::Plugin::Extensions
  # Simplify typing (not reached through down to instances of Plugin instances)
  include OpenRubyRMK
  include OpenRubyRMK::Common
  
  #Checks whether or not this plugin is capable of processing a specific request.
  #==Parameter
  #[req] Either a OpenRubyRMK::Common::Request instance or a string denoting the
  #      request type you want to query. See OpenRubyRMK::Common::Request#type for
  #      more information on how this string should be formed.
  #==Return value
  #Either true or false.
  def can_process_request?(req)
    # The methods tested for here are defined via #process_request
    # and #process_response.
    
    if req.kind_of?(Request)
      respond_to?(:"process_#{req.type}_request", true)
    else
      respond_to?(:"process_#{req}_request", true)
    end
  end

  #This method is usually called inside Protocol#process_request.
  #It hands a request and the Client instance that sent it to the
  #plugin that in turn calls the code registered for handling
  #that request (via #process_request (without bang !) in the DSL).
  #==Parameters
  #[req]    A Request instance. The request to process.
  #[client] The instance of Client that sent the request.
  #==Raises
  #[ArgumentError] This plugin can’t handle the given request type.
  #==Example
  #See the (private) Protocol#process_command method for an example.
  def process_request!(req, client)
    if can_process_request?(req)
      #These two are needed for nice DSL methods such as #answer to work.
      #Only used in: This method, #answer.
      @__current_request = req
      @__current_client  = client
      
      #Invoke the processing method
      send("process_#{req.type}_request", req, client)

      #Reset the client/request cache
      @__current_request = nil
      @__current_client  = nil
    else
      raise(ArgumentError, "The #@name plugin can't process #{req.type} requests!")
    end
  end

  protected

  #call-seq:
  #  process_request(type){|request, sender|...}
  #
  #Part of the Plugin DSL. Creates a new request type that gets available
  #when your plugin is included into Karfunkel. To be exact, this method
  #defines a private method with your codeblock attached to it that is
  #executed when the defined request type is asked for.
  #==Parameter
  #[type]    A symbol for the request type you want to define. This must
  #          match exactly with the request XML’s TYPE attribute.
  #[request] (Blockargument) The Request instance we want to process.
  #[sender]  (Blockargument] The Client instance that the request was sent by.
  #==Example
  #  process_request :Foo do |request, sender|
  #    puts "I got a Foo request with ID #{request.id}!"
  #  end
  def process_request(type, &block)
    sym = :"process_#{type}_request"
    define_method(sym, &block)
    private(sym)
  end
  
  #call-seq:
  #  process_response(type){|response, sender|...}
  #
  #Part of the Plugin DSL. Teaches Karfunkel how to process the given
  #response type. To be exact, this method defines a private method with
  #your codeblock attached to it that is executed when the defined
  #response type is asked for.
  #==Parameter
  #[type]     A symbol for the response type you want to define. This must
  #           match exactly with the TYPE XML attribute of the request that
  #           triggered this response.
  #[response] The Response instance we want to process.
  #[sender]   The Client instance that the response was sent by.
  #==Example
  #  process_response :Foo do |response|
  #    puts "I received a response to a Foo request that had the ID #{response.request.id}!"
  #  end
  def process_response(type, &block)
    sym = :"process_#[type}_request"
    define_method(sym, &block)
    private(sym)
  end

  #Part of the plugin DSL. Instructs Karfunkel to answer the running
  #request.
  #==Parameters
  #[status] The status of the response. See the Response class for more details.
  #[*args]  Any parameters to pass along with the request. A hash.
  #==Raises
  #[RuntimeError] You called this method somewhere where no request and/or
  #               client was available, most likely outside a #process_reponse
  #               block.
  #==Example
  #  process_request :Foo do |request, client|
  #    answer :reject, :reason => "I don't like you."
  #  end
  def answer(status, *args)
    raise("No request available!") unless @__current_request
    raise("No client available!")  unless @__current_client
    
    res = Common::Response.new(Karfunkel.generate_request_id, status, @__current_request)
    Karfunkel.deliver_response(res, @__current_client)
  end

  #Part of the plugin DSL. Your direct access to Karfunkel’s logger.
  #==Return value
  #An instance of Logger (class from Ruby’s stdlib).
  #==Examples
  #  logger.debug "Debugging information"
  #  logger.info "Someone connected!"
  #  logger.warn "I suspect him planning evil things!"
  #  logger.error "He actually did evil things!"
  #  logger.fatal "Now I have to crash!!"
  def logger
    Karfunkel::THE_INSTANCE.log
  end

  #call-seq:
  #  kf()        → OpenRubyRMK::Karfunkel::THE_INSTANCE
  #  karfunkel() → OpenRubyRMK::Karfunkel::THE_INSTANCE
  #
  #Part of the request DSL. Shortcut for typing:
  #  OpenRubyRMK::Karfunkel::THE_INSTANCE
  #==Example
  #  puts "The currently active project is #{k.selected_project}."
  def karfunkel
    Karfunkel::THE_INSTANCE
  end
  alias kf karfunkel

end

# Add plugin extensions to raw Karfunkel
# (this file is loaded only when the Core plugin is being activated,
# not when the plugins are required, so this is safe)
OpenRubyRMK::Karfunkel::Plugin.send(:include, OpenRubyRMK::Karfunkel::Plugin::Extensions)
