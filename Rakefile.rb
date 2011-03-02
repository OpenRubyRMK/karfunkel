#!/usr/bin/env ruby
#Encoding: UTF-8

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

#===============================================================================
# Require statements
#===============================================================================

require "bundler/setup"
require "open-uri"
require "net/ftp"
gem "rdoc", ">= 3"
require "rdoc/task"
require "rake/clean"
require "pathname"

#===============================================================================
# Editable variables
#===============================================================================

#Remote Ruby source file. Basename will be used as the local filename.
RUBY_DOWNLOAD_URL = "ftp://ftp.ruby-lang.org/pub/ruby/1.9/ruby-1.9.2-p180.tar.bz2"
#Name of the directory contained in RUBY_DOWNLOAD_URL.
RUBY_DOWNLOAD_DIRNAME = Pathname.new("ruby-1.9.2-p180")
#Remote Ruby package file. Basename will also be used as the local filename.
RUBY_WIN32_DOWNLOAD_URL = "http://rubyforge.org/frs/download.php/74299/ruby-1.9.2-p180-i386-mingw32.7z"
#Name of the directory contained in RUBY_WIN32_DOWNLOAD_URL.
RUBY_WIN32_DOWNLOAD_DIRNAME = Pathname.new("ruby-1.9.2-p180-i386-mingw32")
#How many jobs "make" should use when compiling ruby. It's a good idea
#to set this to the number of cores your processor has.
MAKE_JOBS = 4
#The gems that will be installed ontop of the downloaded Ruby.
GEMS = %w[gosu chingu]

#===============================================================================
# Other variables
#===============================================================================

#After removing these files the generated result is still usable.
CLEAN.include(File.basename(RUBY_DOWNLOAD_URL), RUBY_DOWNLOAD_DIRNAME.to_s,
  File.basename(RUBY_WIN32_DOWNLOAD_URL), "OpenRubyRMK", "OpenRubyRMK.rb")

#Removing these files gives us a blank environment.
CLOBBER.include("ruby/**/**", "OpenRubyRMK.tar.bz2", "OpenRubyRMK.zip")

#Where to redirect output in order to get suppressed.
NULL = RUBY_PLATFORM =~ /mingw|mswin/ ? "nul" : "/dev/null"

ROOT_DIR = Pathname.new(__FILE__).dirname.expand_path

SERVER_DIR = ROOT_DIR + "server"
CLIENTS_DIR = ROOT_DIR + "clients"
GUI_CLIENT_DIR = CLIENTS_DIR + "gui"
RUBY_DIR = SERVER_DIR + "ruby"
HANNA_CSS_FILE = Pathname.new("doc/css/style.css")

VERSION_FILES = [
  SERVER_DIR + "VERSION.txt",
  GUI_CLIENT_DIR + "VERSION.txt"
  ].freeze

VERSION = {}

ary = VERSION_FILES.first.readlines.map(&:chomp)
ary[0].match(/^(\d+)\.(\d+)\.(\d+)(-dev)?$/)

VERSION[:mayor] = $1.to_i
VERSION[:minor] = $2.to_i
VERSION[:tiny] = $3.to_i
VERSION[:is_dev] = !!$4
VERSION[:date] = ary[1]
VERSION.freeze

#===============================================================================
# Helper methods
#===============================================================================

#Same as Rake's normal sh method, but automatically redirects
#output to the null device (nul on Windows, /dev/null otherwise). If
#+redirect_err+ is true, redirects the standard error as well.
def qsh(str, redirect_err = false)
  if redirect_err
    sh "#{str} 2>&1 > #{NULL}"
  else
    sh "#{str} > #{NULL}"
  end
end

#Executes 7-Zip with the given arguments. For example, if you want to
#extract an archive, use
#  z7 "x", "the_archive.7z"
def z7(*args)
  z7_cmd = nil
  begin
    `7z --help` #Backticks since we don't want to emit output, but an error on not-found
    z7_cmd = "7z"
  rescue Errno::ENOENT
    `7za --help` #Raises Errno::ENOENT as well if not found
    z7_cmd = "7za"
  end
  
  qsh "#{z7_cmd} #{args.map{|arg| "'#{arg}'"}.join(' ')}"
end

#Executes the +make+ command, passing it all given arguments. Too
#execute a "make install", you therefore may do
#  make :install
#(All args are converted to strings).
def make(*args)
  cmd = MAKE_JOBS > 1 ? "make -j#{MAKE_JOBS}" : "make"
  args.each{|arg| cmd << " '#{arg}'"}
  sh cmd
end

#Downloads the file at +url+ and places it in the current directory.
#Does nothing if that file already exists.
def download(url)
  file = Pathname.new(File.basename(url))
  print "Downloading #{file}... "
  if file.file?
    puts "Not needed."
  else
    open(url, "rb") do |page|
      file.open("wb") do |f|
        byte = nil
        f.putc(byte) while byte = page.getbyte
      end
    end
    puts "Done."
  end
end

#Invokes the downloaded Ruby interpreter with +str+.
def druby(str)
  r = RUBY_DIR.join('bin', 'ruby')
  raise(Errno::ENOENT, "#{r} not found!") unless r.file?
  sh "'#{r}' #{str}"
end

#Invokes the downloaded RubyGems with +str+.
def dgem(str)
  g = RUBY_DIR.join('bin', 'gem')
  raise(Errno::ENOENT, "#{g} not found!") unless g.file?
  sh "'#{g}' #{str}"
end

#Sets the version in all VERSION.txt files to the given one.
#The version's date is set to today's.
def set_version!(mayor, minor, tiny, stable = true)
  version = "#{mayor}.#{minor}.#{tiny}"
  version << "-dev" unless stable
  
  puts "Setting OpenRubyRMK's version to #{version}."
  VERSION_FILES.each do |filename|
    filename.open("w") do |file|
      file.puts(version)
      file.write(Time.now.strftime("%d.%m.%y"))
    end
  end
end

#===============================================================================
# Task definitions
#===============================================================================

Rake::RDocTask.new do |rt|
  rt.rdoc_dir = "doc"
  rt.rdoc_files.include("**/*.rb", "**/*.rdoc", "COPYING.txt")
  rt.generator = "hanna" #Ignored if not there
  rt.title = "OpenRubyRMK RDocs"
  rt.main = "README.rdoc"
end

#Hanna's definition lists look a bit flat otherwise.
task :rdoc do
  print "Adding style for definition lists... "
  HANNA_CSS_FILE.open("a") do |file|
    file.puts(<<CSS)
dl dt {
	font-weight: bold;
}
CSS
  end
  puts "Done."
end

desc "Creates (with download) a suitable Ruby in ruby/."
task :get_ruby do
  if RUBY_DIR.join("bin").directory?
    puts "Found #{RUBY_DIR}."
    puts "No need to get it."
    next #Neither return nor break work here and since I didn't want such a big if-clause...
  end
  
  print "Checking OS... "
  if RUBY_PLATFORM =~ /mswin32|mingw32/
    puts "Windows."
    puts "We're going to download the RubyInstaller's 7-Zip binary package."
    
    download RUBY_WIN32_DOWNLOAD_URL #Produces File.basename(RUBY_WIN32_DOWNLOAD_URL) <CLEAN>
    
    rm_r RUBY_DIR if RUBY_DIR.directory? #We'll replace it...
    z7 "x", File.basename(RUBY_WIN32_DOWNLOAD_URL)
    mv RUBY_WIN32_DOWNLOAD_DIRNAME, RUBY_DIR #...with the extracted archive.
  else
    puts "Other OS."
    puts "We're going to compile Ruby."
    puts
    puts "WARNING: Make sure that the development headers of these libraries: "
    puts "readline5, openssl, zlib"
    puts "are installed, because they are essential for RubyGems and irb!"
    print "Do you want to continue? (y/n): "
    raise("Aborted by user!") if $stdin.gets =~ /^n/i
    
    download RUBY_DOWNLOAD_URL #Produces File.basename(RUBY_DOWNLOAD_URL) <CLEAN>
    
    sh "tar -xjf #{File.basename(RUBY_DOWNLOAD_URL)}" #Produces RUBY_DOWNLOAD_DIRNAME <CLEAN>
    cd RUBY_DOWNLOAD_DIRNAME
    sh %Q<./configure --enable-shared --prefix="#{RUBY_DIR.expand_path}">
    make
    make :install #Produces "ruby/**/**" <CLOBBER>
    cd ".."
  end
    
end

task :get_gems => :get_ruby do
  dgem "update --system" #Ensure RubyGems is up to date
  dgem "install #{GEMS.join(" ")} --no-ri --no-rdoc"
end

namespace :bump do
  
  desc "Just sets the date of the current version to today's."
  task :update do
    puts "Refreshing version date."
    set_version!(VERSION[:mayor], VERSION[:minor], VERSION[:tiny], !VERSION[:is_dev])
  end
  
  desc "Increases the tiny version. Pass STABLE=true for stable version."
  task :tiny do
    set_version!(VERSION[:mayor], VERSION[:minor], VERSION[:tiny] + 1, !!ENV["STABLE"])
  end
  
  desc "Increases the minor version. Pass STABLE=true for stable version."
  task :minor do
    set_version!(VERSION[:mayor], VERSION[:minor] + 1, 0, !!ENV["STABLE"])
  end
  
  desc "Increases the mayor version. Pass STABLE=true for stable version."
  task :mayor do
    set_version!(VERSION[:mayor] + 1, 0, 0, !!ENV["STABLE"])
  end
  
  desc "Shows the current version number."
  task :show do
    print VERSION[:mayor], ".", VERSION[:minor], ".", VERSION[:tiny]
    print "-dev" if VERSION[:is_dev]
    puts
    puts VERSION[:date]
  end
  
end

desc "Bumps the version to the given VERSION; pass STABLE if necessary."
task :bump do
  raise(ArgumentError, "VERSION not given!") unless ENV["VERSION"]
  set_version!(*ENV["VERSION"].split("."), !!ENV["STABLE"])
end

desc "Compresses OpenRubyRMK into a usable form, DEPRECATED."
task :compress => [:get_ruby, :get_gems] do #Produces "OpenRubyRMK" <CLEAN>
  raise(NotImplementedError, "This task is deprecated in favor of the upcoming web installer!")
  mkdir "OpenRubyRMK"
  cp_r "config", "OpenRubyRMK/config"
  cp_r "game", "OpenRubyRMK/game"
  cp_r "locale", "OpenRubyRMK/locale"
  cp_r "ruby", "OpenRubyRMK/ruby"
  cp "COPYING.txt", "OpenRubyRMK/COPYING.txt"
  
  if RUBY_PLATFORM =~ /mswin32|mingw32/
    z7 = z7_path
    `ocra --help` #Raises Errno::ENOENT if ocra is not found
    
    #OCRA can't cope with the fact that executables may reside in subdirectories,
    #therefore I'll cheat here and create a helper script at the toplevel.
    helpscript =<<EOF
#!/usr/bin/env ruby
#Encoding: UTF-8
#This is a help script for OCRA. It's necessary because
#OCRA can't understand that executables may reside in
#subdirectories.

require_relative "bin/OpenRubyRMK.rb"
EOF
    print "Creating OCRA help script... "
    File.open("OpenRubyRMK.rb", "w"){|file| file.write(helpscript)} #Produces "OpenRubyRMK.rb" <CLEAN>
    puts "Done."
    sh "ocra --quiet --dll ruby.exe.manifest --dll rubyw.exe.manifest #{ENV.has_key?("ORR_MAKE_CONSOLE_APP") ? "--console" : "--windows"} OpenRubyRMK.rb data/**/* lib/**/* bin/**/*"
    mkdir "OpenRubyRMK/bin"
    mv "OpenRubyRMK.exe", "OpenRubyRMK/bin/OpenRubyRMK.exe"
    sh "#{z7} a OpenRubyRMK.zip OpenRubyRMK > nul" #Produces "OpenRubyRMK.zip" <CLOBBER>
  else
    cp_r "bin", "OpenRubyRMK/bin"
    cp_r "data", "OpenRubyRMK/data"
    cp_r "lib", "OpenRubyRMK/lib"
    sh "tar -cjf OpenRubyRMK.tar.bz2 OpenRubyRMK" #Produces "OpenRubyRMK.tar.bz2" <CLOBBER>
  end
end

# desc "Displays a help message"
# task :help do
#   puts(<<HELP)
# USAGE:
#   rake [OPTIONS] [TASK]
#
# DESCRIPTION
# This is OpenRubyRMK's project Rakefile. It provides you with tasks
# to automatically generate a deployable version of OpenRubyRMK. Usually,
# all you need to do is to execute
#
#   rake compress
#
# which gives you an archive containing OpenRubyRMK specifically
# designed for your platform. If that's really everything you want to
# do with the Git sources, it's enough if you have a recent 1.9 Ruby
# installed. Please note that you won't be able to run OpenRubyRMK
# neither from the Git sources nor from the created archive (except you're
# on Windows). See the project's README for more information on this.
#
# WINDOWS
# To compress OpenRubyRMK on Windows, you have to do a bit
# of extra effort. Since the OpenRubyRMK GUI is written in wxRuby
# and wxRuby doesn't use Windows's Visual Styles by default,
# we added the options to overwrite this default. However, in order to
# work you must have the files "ruby.exe.manifest" and
# "rubyw.exe.manifest" in your Ruby installation's bin/ directory.
# You may obtain them from
# http://wiki.ruby-portal.de/wxRuby#Visual_Styles_unter_Windows.
# Additionally, you have to have the wxruby-ruby19 gem installed
# for your Ruby installation, because OCRA (our *.exe generator)
# will run OpenRubyRMK to obtain it's dependencies.
#
# UBUNTU 9.10 (KARMIC) AND NEWER
# There is a problem with the Linux binary of wxRuby provided by
# the wxRuby development team. In order to run OpenRubyRMK
# (not in order to compress it!) you have to get a binary build for
# your system. Either build wxRuby from the sources yourself,
# or use the precompiled gems we provide at
# http://www.github.com/Quintus/OpenRubyRMK/Downloads.
#
# ENVIRONMENT VARIABLES
# The following environment variables influence the compression
# process:
#
#   ORR_MAKE_CONSOLE_APP
#     On Windows, attaches a console to the OpenRubyRMK
#     executable. That's useful for debugging, but should be
#     avoided if you want to deploy the resulting archive. Set it
#     to anything you like, e.g. "yes", the Rakefile will only look
#     wheather it's defined or not.
# HELP
# end
