#!/usr/bin/env ruby
#Encoding: UTF-8

=begin
This file is part of OpenRubyRMK. 

Copyright © 2010 Hanmac, Kjarrigan, Quintus

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

require "open-uri"
require "net/ftp"

begin
  #Try loading hanna first, it's nicer. If you don't have hanna installed, 
  #you should probably have a look at it: http://rubygems.org/gems/hanna. 
  require "hanna/rdoctask"
rescue LoadError
  require "rake/rdoctask"
end
require "rake/clean"

#Remote URL for ruby sources. This is meant to be relative to "ftp://ftp.ruby-lang.org". 
RUBY_DOWNLOAD_DIR = "pub/ruby/1.9/"
#Remote Ruby source file. Will also be used as the local filename. 
RUBY_DOWNLOAD_FILE = "ruby-1.9.1-p429.tar.bz2"
#Name of the directory contained in RUBY_DOWNLOAD_FILE. 
RUBY_DOWNLOAD_DIRNAME = "ruby-1.9.1-p429"
#Remote URL for Windows Ruby package. 
RUBY_WIN32_DOWNLOAD_DIR = "http://rubyforge.org/frs/download.php/71496/"
#Remote Ruby package file. Will also be used as the local filename. 
RUBY_WIN32_DOWNLOAD_FILE = "ruby-1.9.1-p429-i386-mingw32.7z"
#Name of the directory contained in RUBY_WIN32_DOWNLOAD_FILE. 
RUBY_WIN32_DOWNLOAD_DIRNAME = "ruby-1.9.1-p429-i386-mingw32"

#After removing these files the generated result is still usable. 
CLEAN.include(RUBY_DOWNLOAD_FILE, RUBY_DOWNLOAD_DIRNAME, RUBY_WIN32_DOWNLOAD_FILE, "OpenRubyRMK", "OpenRubyRMK.rb")
#Removing these files gives us a blank environment. 
CLOBBER.include("ruby/**/**", "OpenRubyRMK.tar.bz2", "OpenRubyRMK.zip")

#Returns the name of the 7-Zip executable or raises 
#an Errno::ENOENT if none is found. 
def z7_path
  z7 = nil
  begin
    `7z --help` #Backticks since we don't want to emit output, but an error on not-found
    z7 = "7z"
  rescue Errno::ENOENT
    `7za --help` #Raises Errno::ENOENT as well if not found
    z7 = "7za"
  end
  z7
end

Rake::RDocTask.new do |rt|
  rt.rdoc_files.include("lib/**/*.rb", "README.rdoc", "COPYING.txt")
  rt.title = "OpenRubyRMK RDocs"
  rt.main = "README.rdoc"
end


desc "Creates (with download) a suitable Ruby in ruby/."
task :get_ruby do
  if File.directory?("ruby/bin")
    puts "Found ruby/bin/ruby."
    puts "No need to get it."
    next #Neither return nor break work here and since I didn't want such a big if-clause...
  end
  
  print "Checking OS... "
  if RUBY_PLATFORM =~ /mswin32|mingw32/
    puts "Windows."
    puts "We're going to download the RubyInstaller's 7-Zip binary package."
    z7 = z7_path
    
    if File.file?(RUBY_WIN32_DOWNLOAD_FILE)
      puts "Found #{RUBY_WIN32_DOWNLOAD_FILE}."
      puts "No need to download it."
    else
      print "Dowloading #{RUBY_WIN32_DOWNLOAD_FILE}... "
      str = open(RUBY_WIN32_DOWNLOAD_DIR + RUBY_WIN32_DOWNLOAD_FILE, "rb"){|page| page.read} #5MB fit in RAM, don't they?
      puts "Done."
      open(RUBY_WIN32_DOWNLOAD_FILE, "wb"){|f| f.write(str)} #Produces RUBY_WIN32_DOWNLOAD_FILE <CLEAN>
    end
    rm_r "ruby" if File.directory?("Ruby") #We'll replace it... 
    sh "#{z7} x #{RUBY_WIN32_DOWNLOAD_FILE} > nul"
    mv RUBY_WIN32_DOWNLOAD_DIRNAME, "ruby" #...with the extracted archive. 
  else
    puts "Other OS."
    puts "We're going to compile Ruby."
    puts
    puts "WARNING: Make sure that the development headers of these libraries: "
    puts "readline5, openssl, zlib"
    puts "are installed, because they are essential for RubyGems and irb!"
    print "Do you want to continue? (y/n): "
    raise("Aborted by user!") if $stdin.gets =~ /^n/i
    
    if File.file?(RUBY_DOWNLOAD_FILE)
      puts "Found #{RUBY_DOWNLOAD_FILE}."
      puts "No need to download it."
    else
      print "Downloading #{RUBY_DOWNLOAD_FILE}..."
      Net::FTP.open("ftp.ruby-lang.org") do |ftp|
        ftp.login
        ftp.chdir(RUBY_DOWNLOAD_DIR)
        ftp.getbinaryfile(RUBY_DOWNLOAD_FILE) #Produces RUBY_DOWNLOAD_FILE <CLEAN>
      end
      puts "Done."
    end
    
    sh "tar -xjf #{RUBY_DOWNLOAD_FILE}" #Produces RUBY_DOWNLOAD_DIRNAME <CLEAN>
    goal_dir = File.join(File.expand_path(Dir.pwd), "ruby")
    cd RUBY_DOWNLOAD_DIRNAME
    sh %Q<./configure --enable-shared --prefix="#{goal_dir}">
    sh "make"
    sh "make install" #Produces "ruby/**/**" <CLOBBER>
    cd ".."
  end
    
end

task :get_gems => :get_ruby do
  gems = "gosu chingu"
  if RUBY_PLATFORM =~ /mingw|mswin32/
    sh "ruby\\bin\\gem update --system > nul" #Ensure RubyGems is up to date
    sh "ruby\\bin\\gem install #{gems} --no-ri --no-rdoc"
  else
    sh "./ruby/bin/gem update --system > /dev/null" #Ensure RubyGems is up to date
    sh "./ruby/bin/gem install #{gems} --no-ri --no-rdoc"
  end
end

desc "Compresses OpenRubyRMK into a usable form."
task :compress => [:get_ruby, :get_gems] do #Produces "OpenRubyRMK" <CLEAN>
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

desc "Displays a help message"
task :help do
  puts(<<HELP)
USAGE: 
  rake [OPTIONS] [TASK]

DESCRIPTION
This is OpenRubyRMK's project Rakefile. It provides you with tasks 
to automatically generate a deployable version of OpenRubyRMK. Usually, 
all you need to do is to execute

  rake compress

which gives you an archive containing OpenRubyRMK specifically 
designed for your platform. If that's really everything you want to 
do with the Git sources, it's enough if you have a recent 1.9 Ruby 
installed. Please note that you won't be able to run OpenRubyRMK 
neither from the Git sources nor from the created archive (except you're 
on Windows). See the project's README for more information on this. 

WINDOWS
To compress OpenRubyRMK on Windows, you have to do a bit 
of extra effort. Since the OpenRubyRMK GUI is written in wxRuby 
and wxRuby doesn't use Windows's Visual Styles by default, 
we added the options to overwrite this default. However, in order to 
work you must have the files "ruby.exe.manifest" and 
"rubyw.exe.manifest" in your Ruby installation's bin/ directory. 
You may obtain them from 
http://wiki.ruby-portal.de/wxRuby#Visual_Styles_unter_Windows. 
Additionally, you have to have the wxruby-ruby19 gem installed 
for your Ruby installation, because OCRA (our *.exe generator) 
will run OpenRubyRMK to obtain it's dependencies. 

UBUNTU 9.10 (KARMIC) AND NEWER
There is a problem with the Linux binary of wxRuby provided by 
the wxRuby development team. In order to run OpenRubyRMK 
(not in order to compress it!) you have to get a binary build for 
your system. Either build wxRuby from the sources yourself, 
or use the precompiled gems we provide at 
http://www.github.com/Quintus/OpenRubyRMK/Downloads. 

ENVIRONMENT VARIABLES
The following environment variables influence the compression 
process: 

  ORR_MAKE_CONSOLE_APP
    On Windows, attaches a console to the OpenRubyRMK 
    executable. That's useful for debugging, but should be 
    avoided if you want to deploy the resulting archive. Set it 
    to anything you like, e.g. "yes", the Rakefile will only look 
    wheather it's defined or not. 
HELP
end