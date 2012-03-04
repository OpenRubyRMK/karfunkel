# -*- coding: utf-8 -*-

OpenRubyRMK::Karfunkel::Plugin.extend_plugin(:Core) do

  process_request :hello do |request, client|
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

  process_request :ping do |request, client|
    #If Karfunkel gets a PING request, we just answer it as OK and
    #are done with it.
    answer :ok
  end

  process_response :ping do |response, client|
    #Nothing is necessary here, because a client’s availability status
    #is set automatically if it sends a reponse. I just place the
    #method here, because without it we would get a NotImplementedError
    #exception.
  end

end
