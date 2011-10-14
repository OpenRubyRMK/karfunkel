# -*- coding: utf-8 -*-
=begin
This file is part of OpenRubyRMK.

Copyright © 2010 OpenRubyRMK Team

OpenRubyRMK is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

OpenRubyRMK is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with OpenRubyRMK.  If not, see <http://www.gnu.org/licenses/>.
=end

#This is the gemfile used by bundler to determine
#which gems should be installed.
#For a normal *nix user you have to run
#  $ bundle install --without development
#to make your Ruby ready to run OpenRubyRMK.
#Windows users shouldn't even see this file, as they
#get a *.exe.
#For those who want to develop OpenRubyRMK or just
#want the very latest OpenRubyRMK freshly compressed
#from the git sources, do
#  $ bundle install
#Note that this will install gosu which is a C extension;
#visit the gosu website at http://libgosu.org to
#see what dependencies you need in order to compile
#correctly. For Windows users a pre-build binary of
#gosu exists.

#The source where we download gems from
source "http://rubygems.org"

#gem "wxruby-ruby19", ">= 2.0.0"
gem "r18n-desktop"
gem "minitar", ">= 0.5.3"
gem "chunky_png"
gem "nokogiri"
gem "eventmachine", ">= 1.0.0.beta3"
gem "rake"

group :development do
  gem "rdoc", ">= 3.4"
  gem "RedCloth", :require => "redcloth"
  gem "hanna-nouveau"
  gem "gosu"
  gem "chingu"
  gem "ocra", :platforms => :mswin
  gem "test-unit"
end
