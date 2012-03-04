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

module OpenRubyRMK

  #Mixin module that allows to easily deliver responses from
  #Karfunkel to a given client.
  module Karfunkel::CommandHelpers

    #Sends a +rejected+ response to the +client+.
    #==Parameters
    #[client]  The client to deliver to.
    #[reason]  Reason why the client was rejected.
    #[request] The request that this response is supposed to answer.
    #
    #TODO: Don’t be lazy, Request.new only allows a +nil+ request for :error responses.
    def reject(client, reason, request)
      r = Common::Response.new(Karfunkel::THE_INSTANCE.generate_request_id, :rejected, request)
      r[:reason] = reason
      Karfunkel::THE_INSTANCE.deliver_response(r, client)
    end

    #Sends an +error+ response to the +client+.
    #==Parameters
    #[client]      The client to deliver to.
    #[description] Explanation on what went wrong.
    #[request]     (nil) An optional Request object used to fill the
    #              +type+ and +id+ attributes of the response.
    def error(client, description, request = nil)
      r = Common::Response.new(Karfunkel::THE_INSTANCE.generate_request_id, :error, request)
      r[:description] = description
      Karfunkel::THE_INSTANCE.deliver_response(r, client)
    end

    #Sends an +ok+ response to the +client+.
    #==Parameters
    #[client]  The client to deliver to.
    #[request] The request to answer.
    def ok(client, request)
      r = Common::Response.new(Karfunkel::THE_INSTANCE.generate_request_id, :ok, request)
      Karfunkel::THE_INSTANCE.deliver_response(r, client)
    end

    #Sends a +processing+ response to the +client+.
    #==Parameters
    #[client]  The client to deliver to.
    #[message] Describe your current processing status.
    #[request] The request to answer.
    def processing(client, message, request)
      r = Common::Response.new(Karfunkel::THE_INSTANCE.generate_request_id, :processing, request)
      r[:message] = message
      Karfunkel::THE_INSTANCE.deliver_response(r, client)
    end

    #Sends a +failed+ response to the +client+.
    #==Parameters
    #[client]  The client to deliver to.
    #[reason]  Why the long-running request has failed.
    #[request] The request to answer.
    def failed(client, reason, request)
      r = Common::Response.new(Karfunkel::THE_INSTANCE.generate_request_id, :failed, request)
      r[:reason] = reason
      Karfunkel::THE_INSTANCE.deliver_response(r, client)
    end

    #Sends a +finished+ response to the +client+.
    #==Parameters
    #[client]  The client to deliver to.
    #[request] The request to answer.
    def finished(client, request)
      r = Common::Response.new(Karfunkel::THE_INSTANCE.generate_request_id, :finished, request)
      Karfunkel::THE_INSTANCE.deliver_response(r, client)
    end

  end

end
