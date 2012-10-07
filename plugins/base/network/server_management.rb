# -*- coding: utf-8 -*-
# Server control and authentication.

module OpenRubyRMK::Karfunkel::Plugin::Base

  #All loaded projects as an array.
  attr_reader :projects
  #The currently selected project. +nil+ if no project
  #is selected currently.
  attr_reader :selected_project

  #*Hooked*. Sets up basic project management
  #infrastructure.
  def start
    super
    @projects         = []
    @selected_project = nil
  end

  process_request :hello do
    answer! :rejected, :reason => :already_authenticated if client.authenticated?
    log.debug "Trying to authenticate '#{client}'..."

    #TODO: Here one could add password checks and other nice things
    client.id            = kf.generate_client_id
    client.authenticated = true
    
    log.info "[#{client}] Authenticated."
    
    answer :ok, :my_version => OpenRubyRMK::Karfunkel::VERSION,
           :my_project      => kf.selected_project.to_s,
           :my_clients_num  => kf.clients.count,
           :your_id         => client.id
  end

  process_request :ping do
    #If Karfunkel gets a PING request, we just answer it as OK and
    #are done with it.
    answer :ok
  end

  process_response :ping do
    #Nothing is necessary here, because a client’s availability status
    #is set automatically if it sends a reponse. I just place the
    #method here, because without it we would get a NotImplementedError
    #exception.
  end

  process_request :shutdown do
    # Trying to stop the server will issue requests
    # to all connected clients asking them to agree
    answer :ok
    OpenRubyRMK::Karfunkel.instance.stop(client)
  end

  # If we get this, a SHUTDOWN request has been answered.
  process_response :shutdown do
    client.accepted_shutdown = request.status == "ok" ? true : false
    log.info("[#{client}] Shutdown accepted")
    # If all clients have accepted, stop the server
    OpenRubyRMK::Karfunkel.instance.stop! if OpenRubyRMK::Karfunkel.instance.clients.all?(&:accepted_shutdown)
  end

end
