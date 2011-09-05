#Encoding: UTF-8

OpenRubyRMK::Karfunkel::SM::Request.define :Hello do
  
  parameter :os
  
  def execute(pars)
    answer :reject, :reason => "Already authenticated!" and return if @sender.authenticated?
    Karfunkel.log_debug("Trying to authenticate '#@sender'...")
    
    #TODO: Here one could add password checks and other nice things...
    @sender.id = Karfunkel.generate_id
    @sender.authenticated = true
    
    Karfunkel.log_info("[#@sender] Authenticated.")
    answer :ok, :id => @sender.id, :my_version => OpenRubyRMK::VERSION, :my_project => Karfunkel.selected_project.to_s, :my_clients_num => Karfunkel.clients.count
  end
  
end
