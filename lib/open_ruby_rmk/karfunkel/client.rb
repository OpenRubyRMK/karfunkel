# -*- coding: utf-8 -*-
# 
# This file is part of OpenRubyRMK.
# 
# Copyright © 2010,2011 OpenRubyRMK Team
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

#This is a client that sits on the other end of the connection.
#Objects of this class are automatically instanciated by the
#OpenRubyRMK::Karfunkel::Protocol module.
class OpenRubyRMK::Karfunkel::Client
  
  #The operating system a client uses.
  attr_accessor :os
  #The ID assigned to this client.
  attr_accessor :id
  #Wheather or not a client has already been authenticated.
  attr_accessor :authenticated
  #Wheather or not data can be send to this client.
  #This is set *manually* and does *not* check the
  #actual state of the connection. It’s used by the
  #PING request that sets it to false, whereas every
  #successful request makes it true.
  attr_accessor :available
  attr_accessor :accepted_shutdown
  #The client's IP address.
  attr_reader :ip
  #The port the client uses for the connection.
  attr_reader :port
  #The connection this client is tied to. This is an anonymous,
  #EventMachine-generated class that mixes in the OpenRubyRMK::Karfunkel::Protocol
  #module.
  attr_reader :connection
  
  #Creates a new Client instance. This method is called automatically
  #in Core::Protocol#post_init and isn’t intended to be used elsewhere.
  #==Parameters
  #[connection] The connection the client uses; usually only available
  #             inside the Protocol module as +self+.
  #==Return value
  #The newly created instance.
  #==Example
  #See the sourcode of Core::Protocol#post_init.
  def initialize(connection)
    @connection             = connection
    @authenticated          = false
    @accepted_shutdown      = false
    @available              = true
    if peer = @connection.get_peername
      @port, @ip = Socket.unpack_sockaddr_in(peer)
    else
      @port = "?"
      @ip   = "(unknown)"
    end
  end
  
  #True if the client is authenticated.
  def authenticated?
    @authenticated
  end
  
  #True if the client can be sent data (see the attribute for further
  #explanation).
  def available?
    @available
  end
  
  #Human-readable description of form
  #  #<OpenRubyRMK::Karfunkel::Plugins::Core::Client <ipaddress>>
  def inspect
    "#<#{self.class} #{ip}>"
  end
  
  #The client's IP address.
  def to_s
    @ip
  end
  
end
