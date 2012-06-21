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

gem "rdoc"
require "rake"
require "rake/clean"
require "rubygems/package_task"
require "rdoc/task"
require "pathname"
require_relative "lib/open_ruby_rmk/karfunkel"

namespace :test do

  desc "Run the unit tests."
  task :unit do
    cd "test/unit"
    Dir["test_*.rb"].each do |file|
      load(file)
    end
  end

  desc "Run the functional server tests."
  task :functional do
    cd "test"
    Dir["test_*.rb"].each do |file|
      ruby file
    end
  end

  desc "Run the complete test suite."
  task :all => [:unit, :functional]

end

Rake::RDocTask.new do |rt|
  rt.rdoc_dir  = "doc/html"
  rt.rdoc_files.include("lib/**/*.rb", "plugins/**/*.rb", "**/*.rdoc", "COPYING")
  rt.title     = "OpenRubyRMK RDocs"
  rt.main      = "README.rdoc"
end

# GEMSPEC is defined in `karfunkel.gemspec'
load "openrubyrmk-karfunkel.gemspec"
Gem::PackageTask.new(GEMSPEC).define


