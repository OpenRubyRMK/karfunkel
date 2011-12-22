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
require "psych"
require "yaml"
require "rake"
require "rake/clean"
require "rubygems/package_task"
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
PKG_DIR        = ROOT_DIR + "pkg"
RAKE_DIR       = ROOT_DIR + "rake"
VERSION_FILE   = ROOT_DIR + "CENTRAL_VERSION"
HANNA_CSS_FILE = DOC_DIR + "css" + "style.css"

VERSION    = File.read(VERSION_FILE).chomp
COMPONENTS = %w[karfunkel common]

CLOBBER.include(DOC_DIR.to_s)
COMPONENTS.each{|comp| CLOBBER.include("#{comp}/VERSION")}

#===============================================================================
#Load everything inside the rake/ directory.
#===============================================================================
#Require doesn’t accept ".rake" files.

Dir["#{RAKE_DIR}/**/*.rake"].each{|file| load(file)}

#===============================================================================
# Task definitions
#===============================================================================

namespace :all do

  desc "Builds the gems for all components"
  task :gems => [:gem, :version] do
    mkdir_p PKG_DIR
    
    COMPONENTS.each do |component|
      cd component
      sh "rake gem"
      cp "pkg/openrubyrmk-#{component}-#{VERSION.gsub("-", ".")}.gem", PKG_DIR
      cd ".."
    end
  end

  desc "Clobbers all component directories."
  task :clob => :clobber do
    COMPONENTS.each do |component|
      cd component
      sh "rake clobber"
      cd ".."
    end
  end

  desc "Builds the RDocs for all components."
  task :rdoc do
    mkdir_p DOC_DIR
    
    COMPONENTS.each do |component|
      cd component
      sh "rake rdoc"
      cp_r "doc", DOC_DIR + "server"
      cd ".."
    end
  end

  desc "Updates all VERSION files to the value in CENTRAL_VERSION."
  task :version do
    COMPONENTS.each do |component|
      puts "Bumping #{component}"
      File.open(File.join(component, "VERSION"), "w") do |f|
        f.write(VERSION)
      end
    end
  end
  
end

gemspec = Gem::Specification.new do |s|
  s.name = "openrubyrmk"
  s.summary = "The free and open-source RPG creation program"
  s.description =<<-DESCRIPTION
This is a meta-gem that pulls in all components of the Open
Ruby RMK, a free and open-source program for creating
role-play games (RPG) written in Ruby. It features a server-
client model that allows multiple persons to work on a
single game via a network connection.
  DESCRIPTION
  s.version = VERSION.gsub("-", ".")
  s.author = "The OpenRubyRMK team"
  s.email = "openrubyrmk@googlemail.com"
  s.platform = Gem::Platform::RUBY
  s.required_ruby_version = ">= 1.9.2"
  COMPONENTS.each{|comp| s.add_dependency("openrubyrmk-#{comp}")}
  s.has_rdoc = true
  s.extra_rdoc_files = ["README.rdoc", "COPYING"]
  s.rdoc_options << "-" << "OpenRubyRMK RDocs" << "-m" << "README.rdoc"
end
Gem::PackageTask.new(gemspec).define
