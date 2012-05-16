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

#Adds the default values for the configuration options
#used by the +core+ plugin.
module OpenRubyRMK::Karfunkel::Plugin::Core::Configuration

  #Default values for configuration directives used by
  #the +core+ plugin.
  def default_values
    super.merge({
                  :port          => 3141,
                  :log_level     => :info,
                  :log_format    => method(:log_format),
                  :ping_interval => 20,
                  :greet_timeout => 5
                })
  end

  private

  #Default log format.
  def log_format(sev, time, progname, msg)
    time.strftime("%d/%m/%Y %H:%M:%S [#{sev.chars.first}] #{msg}")
  end

end
