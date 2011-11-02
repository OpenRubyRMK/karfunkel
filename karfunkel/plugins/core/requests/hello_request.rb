# -*- coding: utf-8 -*-

OpenRubyRMK::Karfunkel.define_request :Hello do
  
  parameter :os
  
  def execute(pars)
    answer :reject, :reason => "Already authenticated!" and return if @sender.authenticated?
    karfunkel.log_debug("Trying to authenticate '#@sender'...")
    
    #TODO: Here one could add password checks and other nice things...
    @sender.id = karfunkel.generate_id
    @sender.authenticated = true
    
    karfunkel.log_info("[#@sender] Authenticated.")
    answer :ok, :id => @sender.id, :my_version => OpenRubyRMK::VERSION, :my_project => karfunkel.selected_project.to_s, :my_clients_num => karfunkel.clients.count
  end
  
end
