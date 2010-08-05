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

#After removing these files the generated result is still usable. 
CLEAN.include(RUBY_DOWNLOAD_FILE, RUBY_DOWNLOAD_DIRNAME, RUBY_WIN32_DOWNLOAD_FILE, "OpenRubyRMK")
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
  print "Checking OS... "
  if RUBY_PLATFORM =~ /mswin32|mingw32/
    puts "Windows."
    puts "We're going to download the 7-Zip binary package."
    z7 = z7_path
    
    print "Dowloading #{RUBY_WIN32_DOWNLOAD_FILE}... "
    str = open(RUBY_WIN32_DOWNLOAD_DIR + RUBY_WIN32_DOWNLOAD_FILE, "rb"){|page| page.read} #5MB fit in RAM, don't they?
    puts "Done."
    open(RUBY_WIN32_DOWNLOAD_FILE, "wb"){|f| f.write(str)} #Produces RUBY_WIN32_DOWNLOAD_FILE <CLEAN>
    sh "#{z7} x -o{ruby} #{RUBY_WIN32_DOWNLOAD_FILE}" #Produces "ruby/**/**" <CLOBBER>
  else
    puts "Other OS."
    if File.file?("ruby/bin/ruby")
      puts "Found ruby/bin/ruby. No need to compile it."
    else
      puts "We're going to compile Ruby."
      puts
      puts "WARNING: Make sure that the development packes of these libraries: "
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
    
    #Now install the necessary gems. 
    sh "./ruby/bin/gem update --system" #Ensure RubyGems is up to date
    sh "./ruby/bin/gem install gosu chingu --ri --no-rdoc"
  end
    
end

desc "Compresses OpenRubyRMK into a usable form."
task :compress => :get_ruby do #Produces "OpenRubyRMK" <CLEAN>
  mkdir "OpenRubyRMK"
  cp_r "config", "OpenRubyRMK/config"
  cp_r "game", "OpenRubyRMK/game"
  cp_r "locale", "OpenRubyRMK/locale"
  cp_r "ruby", "OpenRubyRMK/ruby"
  cp "COPYING.txt", "OpenRubyRMK/COPYING.txt"
  
  if RUBY_PLATFORM =~ /mswin32|mingw32/
    z7 = z7_path
    raise("You don't have OCRA installed!") unless system("ocra --help")
    
    sh "ocra bin/OpenRubyRMK.rb data/*.* lib/**/**"
    mkdir "OpenRubyRMK/bin"
    mv "OpenRubyRMK.exe", "OpenRubyRMK/bin/OpenRubyRMK.exe"
    sh "#{z7} a OpenRubyRMK.zip OpenRubyRMK" #Produces "OpenRubyRMK.zip" <CLOBBER>
  else
    cp_r "bin", "OpenRubyRMK/bin"
    cp_r "data", "OpenRubyRMK/data"
    cp_r "lib", "OpenRubyRMK/lib"
    sh "tar -cjf OpenRubyRMK.tar.bz2 OpenRubyRMK" #Produces "OpenRubyRMK.tar.bz2" <CLOBBER>
  end
end