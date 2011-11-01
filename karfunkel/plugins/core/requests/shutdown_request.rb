# -*- coding: utf-8 -*-

OpenRubyRMK::Karfunkel.define_request :Shutdown do

  optional_parameter :requestor
  
  def execute(pars)
    Karfunkel.log_info("[#@sender] Requested a shutdown")
    Karfunkel.stop(@sender)
    answer :ok
    
    @shutdown_timer = EventMachine.add_periodic_timer(2) do
      if Karfunkel.clients.all?{|c| c.accepted_shutdown}
        Karfunkel.log_info("All clients agreed, halting server")
        Karfunkel.stop!
      end
    end
  end
  
  def process_response(resp)
    if resp.type == :rejected
      Karfunkel.log_info("[#{resp.sender}] Rejected server shutdown, reason: #{resp["reason"]}")
      @shutdown_timer.cancel
    else
      Karfunkel.log_info("[#{resp.sender}] Accepted server shutdown.")
      resp.sender.accepted_shutdown = true
    end
  end
  
end
