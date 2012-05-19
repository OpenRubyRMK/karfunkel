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

    ##
    # :method: rejected
    #call-seq:
    #  rejected(client, request, hsh)
    #
    #Like #ok, but for the +rejected+ status.

    ##
    # :method: error
    #call-seq:
    #  error(client, request, hsh)
    #
    #Like #ok, but for the +error+ status.

    ##
    # :method: ok
    #call-seq:
    #  ok(client, request, hsh)
    #
    #Delivers the +ok+ response.
    #==Parameters
    #[client] The client to deliver to.
    #[request] The request to answer.
    #[hsh]     Any information you want to include into the response
    #          as a hash (both keys and values will be converted
    #          to string on delivering).

    ##
    # :method: processing
    #call-seq:
    #  processing(client, request, hsh)
    #
    #Like #ok, but for the +processing+ status.

    ##
    # :method: failed
    #call-seq:
    #  failed(client, request, hsh)
    #
    #Like #ok, but for the +failed+ status.

    ##
    # :method: finished
    #call-seq:
    #  finished(client, request, hsh)
    #
    #Like #ok, but for the +finished+ status.

    #Convenience method to access all the response-specific
    #methods by a single name.
    #==Parameters
    #[client]  The client to deliver to.
    #[request] The request to answer.
    #[status]  The request status, i.e. the name of the
    #          response-specific method you want to call.
    #[hsh]     Any information you want to include into the response
    #          as a hash (both keys and values will be converted
    #          to string on delivering).
    #==Raises
    #[NoMethodError] No method for answering with +status+ exists.
    def answer(client, request, status, hsh)
      if respond_to?(status)
        send(status, client, request, hsh)
      else
        raise(NoMethodError, "Unknown answer method '#{status}'!")
      end
    end

    [:rejected, :error, :ok, :processing, :failed, :finished].each do |sym|
      define_method(sym) do |client, request, hsh|
        res = Common::Response.new(Karfunkel.instance.generate_request_id, sym, request)
        hsh.each_pair{|k, v| res[k] = v}
        Karfunkel.instance.deliver_response(res, client)
      end
    end

  end

end
