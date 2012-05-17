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

module OpenRubyRMK::Karfunkel::Plugin::Base
  include OpenRubyRMK::Karfunkel::Plugin

  process_request :hello do |c, r|
    answer :rejected, :reason => "Already authenticated" and return if c.authenticated?
    log.debug "Trying to authenticate '#{}'..."

    #TODO: Here one could add password checks and other nice things
    c.id            = kf.generate_client_id
    c.authenticated = true
    
    log.info "[#{c}] Authenticated."
    
    answer c, r, :ok, :my_version => OpenRubyRMK::Karfunkel::VERSION,
                 :my_project      => kf.selected_project.to_s,
                 :my_clients_num  => kf.clients.count,
                 :your_id         => c.id
  end

  process_request :ping do |c, r|
    #If Karfunkel gets a PING request, we just answer it as OK and
    #are done with it.
    answer c, r, :ok
  end

  process_response :ping do |c, r|
    #Nothing is necessary here, because a client’s availability status
    #is set automatically if it sends a reponse. I just place the
    #method here, because without it we would get a NotImplementedError
    #exception.
  end

  # If we get this, a SHUTDOWN request has been answered.
  process_response :shutdown do |c, r|
    c.accepted_shutdown = r.status == "ok" ? true : false
    # If all clients have accepted, stop the server
    OpenRubyRMK::Karfunkel.instance.stop! if OpenRubyRMK::Karfunkel.instance.clients.all?(&:accepted_shutdown)
  end

end
