OpenRubyRMK::Karfunkel::Plugin.extend_plugin(:Core) do

  process_request :Hello do |request, client|
    answer :rejected, :reason => "Already authenticated" and return if client.authenticated?
    logger.debug "Trying to authenticate '#{client}'..."

    #TODO: Here one could add password checks and other nice things
    client.id            = kf.generate_client_id
    client.authenticated = true
    
    logger.info "[#{client}] Authenticated."
    
    answer :ok, :my_version     => Karfunkel::VERSION, 
                :my_project     => kf.selected_project.to_s,
                :my_clients_num => kf.clients.count
  end

end
