# -*- coding: utf-8 -*-

OpenRubyRMK::Karfunkel.define_request :Eval do

  parameter :code
  
  def execute(pars)
    if karfunkel.debug_mode?
      karfunkel.log_debug("[#{client} Executing EVAL request]")
      res = nil
      begin
        res = eval(pars[:code])
        answer :ok,  :result => res.inspect, :exception => false
      rescue Exception => e
        karfunkel.log_exception(e)
        answer :failed, :result => "", :exception => true, :class => e.class, :message => e.message, :bactrace => e.backtrace.join("|")
      ensure
        karfunkel.log_debug("[#{client} Finished EVAL request]")
      end
    else
      answer client, :reject,  :reason => "Not running in debug mode!"
      karfunkel.log_warn("[#{client}] Rejected an EVAL request!")
    end
  end
  
end
