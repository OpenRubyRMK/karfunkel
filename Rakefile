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
require "erb"
require "kramdown"
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

task :reqdocs do
  cd "doc/protocol" do
    top_dir = Pathname.pwd

    # Parse the skeleton
    template = ERB.new(File.read("skeleton.html.erb"))

    Pathname.pwd.find do |path|
      next unless path.to_s.end_with?(".md")
      puts "Processing #{path}..."

      # Transform our meta-markdown to raw markdown
      text = parse_meta_markdown(path.read)

      # Convert the content to HTML
      html_text = Kramdown::Document.new(text).to_html

      # Insert the main content into the page skeleton
      content = {}
      content[:root] = top_dir.relative_path_from(path.dirname)
      content[:main] = html_text
      result = template.result(binding)

      # Write the resulting HTML out to disk
      path.sub_ext(".html").open("w") do |file|
        file.write(result)
      end
    end
  end
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

########################################
# Helper methods

# Takes text written in a slightly enhanced version of
# Markdown and transforms it down to bare Markdown you
# can feed to Kramdown.
def parse_meta_markdown(text)
  result = ""

  text.each_line do |line|
    case line
    when /^\+\[(\w+?)\]\+{4,}/ then result << %Q{<div class="#$1" markdown="1">\n} # Opening tag
    when /^\+{5,}/             then result << "</div>\n" # Closing tag
    when /^%%/                 then nil # Comment — ignore
    else
      result << line
    end
  end

  result
end
