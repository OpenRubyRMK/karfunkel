# -*- coding: utf-8 -*-

OpenRubyRMK::Karfunkel.define_request :Shutdown do

  optional_parameter :requestor
  
  def execute(pars)
    karfunkel.log_info("[#@sender] Requested a shutdown")
    karfunkel.stop(@sender)
    answer :ok
    
    @shutdown_timer = EventMachine.add_periodic_timer(2) do
      if karfunkel.clients.all?{|c| c.accepted_shutdown}
        karfunkel.log_info("All clients agreed, halting server")
        karfunkel.stop!
      end
    end
  end
  
  def process_response(resp)
    if resp.type == :rejected
      karfunkel.log_info("[#{resp.sender}] Rejected server shutdown, reason: #{resp["reason"]}")
      @shutdown_timer.cancel
    else
      karfunkel.log_info("[#{resp.sender}] Accepted server shutdown.")
      resp.sender.accepted_shutdown = true
    end
  end
  
end
