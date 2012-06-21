# -*- mode: ruby; coding: utf-8 -*-
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

GEMSPEC = Gem::Specification.new do |spec|

  # Project information
  spec.name        = "openrubyrmk-karfunkel"
  spec.summary     = "The OpenRubyRMK server"
  spec.description =<<-DESCRIPTION
This is the server component of the OpenRubyRMK, the free and 
open-source RPG creation program written in Ruby.
  DESCRIPTION
  spec.version     = File.read("VERSION").strip.gsub("-", ".")
  spec.author      = "The OpenRubyRMK team"
  spec.email       = "openrubyrmk@googlemail.com"

  # Requirements
  spec.platform              = Gem::Platform::RUBY
  spec.required_ruby_version = ">= 1.9.2"
  spec.add_dependency("nokogiri")
  spec.add_dependency("eventmachine", ">= 1.0.0.beta.4")

  # Gem contents
  spec.files = [Dir["bin/*"],
                Dir["config/**/*"],
                Dir["game/**/*"],
                Dir["lib/**/*"],
                Dir["plugins/**/*"],
                "VERSION",
                "README.rdoc",
                "COPYING"].flatten
  spec.has_rdoc         = true
  spec.extra_rdoc_files = ["README.rdoc", "COPYING"]
  spec.rdoc_options << "-t" << "Karfunkel RDocs" << "-m" << "README.rdoc"

end
