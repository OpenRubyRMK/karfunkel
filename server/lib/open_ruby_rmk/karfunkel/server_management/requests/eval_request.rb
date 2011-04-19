#Encoding: UTF-8

OpenRubyRMK::Karfunkel::SM::Request.define :Eval do
  
  attribute :code
  
  def execute(client)
    if Karfunkel.debug_mode?
      Karfunkel.log_debug("[#{client} Executing EVAL request]")
      res = nil
      begin
        res = eval(self[:code])
        answer :ok,  :result => res.inspect, :exception => false
      rescue Exception => e
        Karfunkel.log_exception(e)
        answer :ok, :result => "", :exception => true, :class => e.class, :message => e.message, :bactrace => e.backtrace.join("|")
      ensure
        Karfunkel.log_debug("[#{client} Finished EVAL request]")
      end
    else
      answer :reject,  :reason => "Not running in debug mode!"
      Karfunkel.log_warn("[#{client}] Rejected an EVAL request!")
    end
  end
  
end