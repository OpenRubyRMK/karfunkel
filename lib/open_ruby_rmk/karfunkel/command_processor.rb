# -*- coding: utf-8 -*-
# 
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

#The CommandProcessor is responsible for identifying which plugin
#is responsible for handling a specific request or response. As
#such, its main method #process_command takes the client that sent
#the response (in order to forward it to the responsible plugin) and
#the command to filter the requests and responses from and calls out
#for the responsible plugin’s processing mechanism.
#
#This class is usually just used inside the Protocol module as
#that’s where data usually arrives just before it enters Karfunkel.
#It can however be used to simulate requests and related data to
#the server.
#
#Basicly this is a singleton class as only the Karfunkel class makes
#use of it, but as it doesn’t has any state, multiple instances
#of this class don’t hurt. Maybe I will turn it into a module
#sometime, but it appears more logically to me if the command
#processor is a _part_ of Karfunkel, reachable through his
#+processor+ attribute.
class OpenRubyRMK::Karfunkel::CommandProcessor
  include OpenRubyRMK
  include Karfunkel::CommandHelpers

  #Checks if the user is authenticated, and if so, immediately
  #returns. If not, this method verifies that +command+ contains
  #a single +Hello+ request and nothing else. Note that this
  #method just detects structural errors, because the actual
  #authentication takes place during the execution of the
  #+Hello+ request.
  #==Parameters
  #[client]  The client whose authentication status you want to check.
  #[command] The commond whose validity for an authentication request
  #          (+Hello+) you want to check.
  #==Raises
  #[AuthenticationError] The client isn’t authenticated and the command
  #                      isn’t suitable for authentication (i.e. it
  #                      isn’t just a +Hello+ request).
  def check_authentication(client, command)
    return if client.authenticated?
    #OK, not authenticated. This means, the first request the client
    #sends must be HELLO, and no further requests in this command are
    #allowed.
    if command.requests.count > 1
      raise(Common::Errors::AuthenticationError.new(@client), "Client #@client tried to execute requests together with HELLO!")
    elsif command.requests.first.type != "hello"
      raise(Common::Errors::AuthenticationError.new(@client), "Client #@client tried to send another request than a HELLO!")
    end
    #Good, no malicious attempts so far. Return and let the HELLO request
    #class check credentials, etc.
  end

  #Main processor method. This method iterates through all requests,
  #responses and notifications found in the given +command+, finds
  #out which plugin is able to process it, and finally invokes
  #the respective processing method on the plugin, passing the
  #+client+ given.
  #==Parameters
  #[client]  The client that sent the +command+.
  #[command] The command to process.
  #==Remarks
  #This method shouldn’t raise, but rather send a +Reject+ response
  #to the client when something goes wrong.
  def process_command(client, command)
    command.requests.each do |request|
      begin
        Karfunkel::THE_INSTANCE.log.info("[#{client}] Request: #{request.type}")

        plugin = Karfunkel::THE_INSTANCE.config[:plugins].find{|p| p.can_process_request?(request)}
        if plugin
          plugin.process_request(request, client)
        else
          Karfunkel::THE_INSTANCE.log.warn("[#{client}] No plugin understands this request type: #{request.type}. Rejecting.")
          reject(client, "Unknown request type #{request.type}. I'm sorry I can't help you.", request)
        end
      rescue => e
        Karfunkel::THE_INSTANCE.log_exception(e)
        reject(client, e.message, request)
      end
    end
    
    #And now we check the responses that Karfunkel’s clients send to us.
    #See the Transformer class for information on how Request and Response
    #instances are connected to each other.
    command.responses.each do |response|
      begin
        Karfunkel::THE_INSTANCE.log.info("[#{client}] Received response to a #{response.request.type} request")
        plugin = Karfunkel::THE_INSTANCE.config[:plugins].find{|p| p.can_process_response?(response)}
        plugin.process_response(response, client)
      rescue => e
        Karfunkel::THE_INSTANCE.log_exception(e)
        Karfunkel::THE_INSTANCE.log.error("[#{client}] Failed to process response: #{response}")
      end
    end
  end

end
