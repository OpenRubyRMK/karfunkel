#Encoding: UTF-8

OpenRubyRMK::Karfunkel::SM::Request.define :Hello do
  
  attribute :os
  
  def execute(client)
    answer :reject, :reason => "Already authenticated!" and return if client.authenticated?
    Karfunkel.log_debug("Trying to authenticate '#{client}'...")
    
    #TODO: Here one could add password checks and other nice things...
    client.id = Karfunkel.generate_id
    client.authenticated = true
    
    Karfunkel.log_info("[#{client}] Authenticated.")
    answer :ok, :id => client.id, :my_version => OpenRubyRMK::VERSION, :my_project => Karfunkel.selected_project.to_s, :my_clients_num => Karfunkel.clients.count
  end
  
end