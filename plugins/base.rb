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

#The base plugin provides Karfunkel with the necessary infrastructure
#to act properly. It defines things like how to act upon a +shutdown+
#request and the project management things. Unless you really know
#what you’re doing, you want this plugin to be enabled.
module OpenRubyRMK::Karfunkel::Plugin::Base
  include OpenRubyRMK::Karfunkel::Plugin

  # When this plugin is required, load the dependency
  # libraries of this plugin and all parts of this
  # plugin.
  def self.included(*)
    # Dependency libs
    require "base64"
    require "zlib"
    require "archive/tar/minitar"
    require "tiled_tmx"

    # All the network interface stuff
    require_relative "base/network/server_management"
    require_relative "base/network/projects"
    require_relative "base/network/global_scripts"
    require_relative "base/network/tilesets"
    require_relative "base/network/maps"
    require_relative "base/network/categories"

    # All the classes
    require_relative "base/api/invalidatable"
    require_relative "base/api/project"
    require_relative "base/api/map"
    require_relative "base/api/category"
  end

end
