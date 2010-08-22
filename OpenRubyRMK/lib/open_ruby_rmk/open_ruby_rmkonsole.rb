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

module OpenRubyRMK
  
  #OpenRubyRMK's CUI. 
  module OpenRubyRMKonsole
    
    #The version of the CUI. 
    VERSION = "0.0.1-dev"
    
    #The banner that gets displayed every time you start the CUI. 
    BANNER =<<BANNER
================================================================================
OpenRubyRMK Copyright (C) 2010 OpenRubyRMK Team
This program comes with ABSOLUTELY NO WARRANTY; for details type 'warranty'.
This is free software, and you are welcome to redistribute it
under certain conditions; type 'copyright' for details.

This is OpenRubyRMKonsole, the console of the OpenRubyRMK editor!
You're experiencing version #{VERSION}, have fun and type 'help' for 
more information (and help, of course). 

Found a bug in RMKonsole? Feel free to file an issue at 
http://github.com/Quintus/OpenRubyRMK/issues!

Now... Ready?
Set!
Go!
================================================================================
BANNER
    
    #OpenRubyRMK's copyright statement, available via the "copyright" command. 
    COPYRIGHT=<<COPYRIGHT
OpenRubyRMK Copyright (C) 2010 OpenRubyRMK Team
This is free software, see COPYING.txt for copying conditions. There is NO 
warranty; not even for MERCHANTIBILITY or FITNESS FOR A PARTICULAR PURPOSE.
COPYRIGHT
    
    #The GNU GPL's disclaimer of warranty, available via the "warranty" command. 
    WARRANTY=<<WARRANTY
  THERE IS NO WARRANTY FOR THE PROGRAM, TO THE EXTENT PERMITTED BY
APPLICABLE LAW.  EXCEPT WHEN OTHERWISE STATED IN WRITING THE COPYRIGHT
HOLDERS AND/OR OTHER PARTIES PROVIDE THE PROGRAM "AS IS" WITHOUT WARRANTY
OF ANY KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO,
THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
PURPOSE.  THE ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE PROGRAM
IS WITH YOU.  SHOULD THE PROGRAM PROVE DEFECTIVE, YOU ASSUME THE COST OF
ALL NECESSARY SERVICING, REPAIR OR CORRECTION.
WARRANTY
    
    
    #This module contains every command that is executable in the CUI. 
    module Commands
      
      class << self
        
        def help
          puts "Help!\n"
        end
        
        def copyright
          puts COPYRIGHT
        end
        
        def warranty
          puts WARRANTY
        end
        
        def ruby(line = nil)
          if line
            eval(line)
          elsif $stdin.tty?
            puts "End input with __END__"
            ruby = ""
            loop do
              print "ruby>"
              line = gets
              break if line.comp == "__END__"
              ruby << line
            end
            eval(ruby)
          else
            $stderr.puts("Interactive Ruby code only possible in a TTY.")
          end
        end
        
        def ruby_file(file)
          if File.file?(file)
            load(file)
          else
            $stderr.puts("File not found: '#{file}'.")
          end
        end
        
      end
      
    end
    
  end
  
end