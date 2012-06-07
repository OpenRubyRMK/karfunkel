# -*- mode: ruby; coding: utf-8 -*-
#This file is part of OpenRubyRMK.
#
#Copyright © 2012 OpenRubyRMK Team
#
#OpenRubyRMK is free software: you can redistribute it and/or modify
#it under the terms of the GNU General Public License as published by
#the Free Software Foundation, either version 3 of the License, or
#(at your option) any later version.
#
#OpenRubyRMK is distributed in the hope that it will be useful,
#but WITHOUT ANY WARRANTY; without even the implied warranty of
#MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#GNU General Public License for more details.
#
#You should have received a copy of the GNU General Public License
#along with OpenRubyRMK.  If not, see <http://www.gnu.org/licenses/>.

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

gem "nokogiri"
gem "eventmachine", ">= 1.0.0.beta.4"
gem "minitar"
gem "ruby-tmx"

group :development do
  gem "paint"
  #gem "ocra", :platforms => :mswin
end
