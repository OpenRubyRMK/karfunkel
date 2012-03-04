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

class OpenRubyRMK::Karfunkel::Simulator
  include OpenRubyRMK

  ID_GENERATOR = 1.upto(Float::INFINITY)

  def initialize
    @requests    = []
    @responses   = []
    @notes       = []
    @transformer = Common::Transformer.new
    @client_id   = 9999999
  end

  def request(type)
    req = Common::Request.new(ID_GENERATOR.next, type)
    yield(req)
    deliver(cmd)
  end

  def deliver(cmd)
    Karfunkel::THE_INSTANCE.processor.process_command(cmd)
  end

end
