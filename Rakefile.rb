# -*- coding: utf-8 -*-
#
# This file is part of OpenRubyRMK.
# 
# Copyright © 2010,2011 OpenRubyRMK Team
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

#===============================================================================
# Require statements
#===============================================================================

#require "bundler/setup"
gem "rdoc", ">= 3"
require "yaml"
require "rake"
require "rake/clean"
require "open-uri"
require "net/ftp"
require "pathname"
require "rdoc/task"
require "redcloth"

#===============================================================================
# Variables
#===============================================================================
#Environment variables influencing the rake tasks’ behaviours:
#
#[MAKE_JOBS] Number of jobs for any `make' commands.

MAKE_JOBS = ENV["MAKE_JOBS"] || 4

ROOT_DIR       = Pathname.new(__FILE__).dirname.expand_path
SERVER_DIR     = ROOT_DIR + "server"
CLIENTS_DIR    = ROOT_DIR + "clients"
INSTALLER_DIR  = ROOT_DIR + "installer"
DOC_DIR        = ROOT_DIR + "doc"
RAKE_DIR       = ROOT_DIR + "rake"
HANNA_CSS_FILE = DOC_DIR + "css" + "style.css"

#===============================================================================
#Load everything inside the rake/ directory.
#===============================================================================
#Require doesn’t accept ".rake" files.

Dir["#{RAKE_DIR}/**/*.rake"].each{|file| load(file)}

#===============================================================================
# Task definitions
#===============================================================================

Rake::RDocTask.new do |rt|
  rt.rdoc_dir = "doc"
  rt.rdoc_files.include("**/*.rb", "**/*.rdoc", "COPYING.txt")
  rt.rdoc_files.exclude("server/lib/open_ruby_rmk/karfunkel/server_management/requests/*.rb")
  rt.generator = "hanna" #Ignored if not there
  rt.title = "OpenRubyRMK RDocs"
  rt.main = "README.rdoc"
end

#Add request documentation to the RDocs.
task :rdoc do
  document_requests
end
