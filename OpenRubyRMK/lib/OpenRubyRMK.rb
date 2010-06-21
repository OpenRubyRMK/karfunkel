#!/usr/bin/env ruby
#Encoding: UTF-8

#Check out the Ruby version
if RUBY_VERSION != "1.9.1"
  $stderr.puts("Unsuitable Ruby version. Please use a 1.9.1 Ruby.")
  exit 1
end

#Now start OpenRubyRMK
#...since the GUI isn't wrote, just do something else. 
#Hey, it's only for testing! 

if RUBY_PLATFORM =~ /linux/
  system("xmessage", 'This is an awesome test for linux platforms!')
elsif RUBY_PLATFORM =~ /mingw|mswin/
  require "win32api"
  msgbox = Win32API.new("user32", "MessageBoxA", 'LPPI', 'I')
  msgbox.call(0, "You're now running OpenRubyRMK! ... At least a test for it.", "OpenRubyRMK", 0)
else
  raise("Unsupported platform!")
end
#Feel free to add test messsages for other platforms 
#until we are building the GUI!