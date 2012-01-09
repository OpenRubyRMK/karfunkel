# -*- mode: ruby; coding: utf-8 -*-

require "rake"
require "rdoc/task"
require "rake/testtask"
require "rake/clean"
require "rubygems/package_task"

require_relative "lib/open_ruby_rmk/common"

########################################
# General information
########################################

PROJECT_TITLE = "OpenRubyRMK common library"

########################################
# Gemspec
########################################

gemspec = Gem::Specification.new do |spec|

  # General information
  spec.name                  = "openrubyrmk-common"
  spec.summary               = "Common library for the OpenRubyRMK's server and default client."
  spec.description           =<<DESC
This library defines all the classes that are used by both the
OpenRubyRMK's server, Karfunkel, and the default OpenRubyRMK client.
If you want to write your own OpenRubyRMK client, you can build on top
of this set of classes, it includes the basic definitions for managing
commands, requests, etc.
DESC
  spec.version               = OpenRubyRMK::Common::VERSION.gsub("-", ".")
  spec.author                = "The OpenRubyRMK Team"
  spec.email                 = "openrubyrmk@googlemail.com"
  spec.homepage              = "http://devel.pegasus-alpha.eu/projects/openrubyrmk"
  spec.platform              = Gem::Platform::RUBY
  spec.required_ruby_version = ">= 1.9"
  
  # Dependencies
  spec.add_development_dependency("hanna-nouveau", ">= 0.2.4")

  # Gem files
  spec.files = Dir["lib/**/*.rb", "test/test_*.rb", "README.rdoc",
                   "COPYING", "VERSION"]
  
  # Options for RDoc
  spec.has_rdoc         = true
  spec.extra_rdoc_files = %w[README.rdoc COPYING]
  spec.rdoc_options     << "-t" << "#{PROJECT_TITLE} RDocs" << "-m" << "README.rdoc"
end
Gem::PackageTask.new(gemspec).define

########################################
# RDoc generation
########################################

RDoc::Task.new do |rt|
  rt.rdoc_dir = "doc"
  rt.rdoc_files.include("lib/**/*.rb", "**/*.rdoc", "COPYING")
  rt.rdoc_files.exclude("server/lib/open_ruby_rmk/karfunkel/server_management/requests/*.rb")
  rt.generator = "hanna" #Ignored if not there
  rt.title = "#{PROJECT_TITLE} RDocs"
  rt.main = "README.rdoc"
end

########################################
# Tests
########################################

Rake::TestTask.new do |t|
  t.test_files = FileList["test/test_*.rb"]
end
