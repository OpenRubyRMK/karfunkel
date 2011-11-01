# -*- coding: utf-8 -*-

OpenRubyRMK::Karfunkel.define_request :ChatMessage do

  parameter :message
  optional_parameter :target
  optional_parameter :original_sender

  def execute(pars)
    if pars["target"].empty? #No destination -> Visible to everyone
      broadcast :chat_message, :original_sender => @sender.id, :message => pars["message"]
    else #Specific receiver
      #Find the receiver
      target = Karfunkel.clients.find{|c| c.id == pars["target"].to_i}
      unless target
        answer :rejected, :reason => "Client #{pars['target']} doesn't exist!"
        return
      end

      #Copy this request to a new one
      req           = self.class.new(Karfunkel, Karfunkel.next_request_id)
      req[:message] = pars["message"]
      req[:target]  = pars["target"] #Shouldn’t be necessary, for completeness
      req[:original_sender] = @sender.id

      #Deliver the request
      target.request(req)
    end
    answer :ok
  end

  def process_response(resp)
    unless resp.type == :ok
      target = Karfunkel.clients.find{|c| c == resp.request[:target].to_i}
      Karfunkel.log_warn("Couldn't deliver chat message from #@sender to #{target}.")
    end
  end

end
