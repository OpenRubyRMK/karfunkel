# -*- coding: utf-8 -*-
# This file is part of OpenRubyRMK.
# 
# Copyright © 2012 OpenRubyRMK Team
# 
# OpenRubyRMK is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
# 
# OpenRubyRMK is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with OpenRubyRMK.  If not, see <http://www.gnu.org/licenses/>.

module OpenRubyRMK::Karfunkel::Plugin::Core

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
