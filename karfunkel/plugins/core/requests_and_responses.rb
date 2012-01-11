OpenRubyRMK::Karfunkel::Plugin.extend_plugin(:Core) do

  process_request :Hello do |request, client|
    answer :rejected, :reason => "Already authenticated" and return if client.authenticated?
    
    Karfunkel::THE_INSTANCE.log_debug("Trying to authenticate '#{client}'...")
    #TODO: Here one could add password checks and other nice things
    client.id            = Karfunkel::THE_INSTANCE.generate_client_id
    client.authenticated = true
    Karfunkel::THE_INSTANCE.log_info("[#{client}] Authenticated.")
    
    answer :ok, :my_version     => Karfunkel::VERSION, 
                :my_project     => Karfunkel::THE_INSTANCE.selected_project.to_s, 
                :my_clients_num => Karfunkel::THE_INSTANCE.clients.count
  end

end
