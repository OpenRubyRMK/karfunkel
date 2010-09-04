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
  
  #OpenRubyRMK's CUI. The files that contain what RMKonsole does are a bit spread over the 
  #directory structure, since I wanted to strictly separate GUI and non-GUI classes. 
  #That means, the full inner GUI terminal is formed by the following files: 
  #* lib/open_ruby_rmkonsole.rb (this file). Defines the commands executable in the CUI. 
  #* lib/gui/controls/terminal.rb. Defines the superclass for the terminal widget. 
  #* lib/gui/controls/rmkonsole.rb. This defines the terminal widget's class. 
  #* lib/gui/windows/console_window.rb. This contains the terminal window's class definition. 
  #Theoretically speaking, it should be possible to write a real CUI for OpenRubyRMK by 
  #using the constants and methods defined under the module inside this file. However, practically 
  #speaking that's unlikely, since the visual representation of the maps makes life a lot 
  #easier. Nevertheless RMKonsole may help you to get away with instantly repeating processes. 
  #Just define a plugin for :rmkonsole that encapsulates what you're doing and call the newly 
  #defined method. TODO: Implement the plugin system for RMKonsole. 
  module OpenRubyRMKonsole
    
    #The version of the CUI. 
    VERSION = "0.0.2-dev"
    
    #The banner that gets displayed every time you start the CUI. 
    BANNER =<<BANNER
================================================================================
OpenRubyRMK, a free and open-source RPG creation program.  
Copyright (C) 2010 OpenRubyRMK Team
This program comes with ABSOLUTELY NO WARRANTY; for details type 'warranty'.
This is free software, and you are welcome to redistribute it
under certain conditions; type 'copyright' for details.

This is OpenRubyRMKonsole, the console of the OpenRubyRMK editor!
You're experiencing version #{VERSION}, have fun and type 'please_help' for 
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
    
    #Destination where the methods in the Main module write to. 
    @output = $stdout
    
    #Location where all output of the methods in the Main module goes to. 
    #$stdout by default, but you should set it to the output of a RMKonsole instance 
    #whenever you create a new one. 
    def self.output
      @output
    end
    
    #See #output for a description. 
    #Setter method. 
    def self.output=(val)
      @output = val
    end
    
    #This module contains every command that is executable in the CUI. 
    #In fact, when using IRB in RMKonsole, the "main" object points to this 
    #module, therefore this documentation can be seen as a kind of "command reference" of RMKonsole. 
    #Note however, that you are free to use the whole OpenRubyRMK API in RMKonsole, 
    #and we encourage you to do so. 
    module Main
      
      class << self
        
        #This is shown inside IRB's prompt. 
        def to_s
          "Main"
        end
        
        #Shows a help message. 
        #TODO. 
        def please_help
          "help!"
        end
        
        #Overwrite Kernel method in order to redirect output to the control. 
        def print(*args)
          OpenRubyRMKonsole.output.print(*args)
        end
        
        #Overwrite Kernel method in order to redirect output to the control. 
        def puts(*args)
          OpenRubyRMKonsole.output.puts(*args)
        end
        
        #Overwrite Kernel method in order to redirect output to the control. 
        def p(*args)
          args.each{|arg| self.puts(arg.inspect)}
        end
        
        #Overwrite Kernel method in order to redirect output to the control. 
        def y(*args)
          args.each{|arg| self.puts(arg.to_yaml)}
          nil
        end
        
        #Shows OpenRubyRMK's copyright statement. 
        def copyright
          self.puts COPYRIGHT
        end
        
        #Show's the Warranty section of the GNU GPL. 
        def warranty
          self.puts WARRANTY
        end
        
        #Adds the given map object to the map hierarchy. 
        #This is exactly what the Edit -> Add map... menu does; 
        #note that the map doesn't get saved automatically, it will 
        #be saved when the user saves the entire project. 
        #If you want to enforce saving of the map, call #save on your 
        #Map object. 
        def add_map_to_gui(map)
          return self.puts("No GUI loaded.") unless defined?(Wx)
          return self.puts("No project selected.") unless OpenRubyRMK.has_project?
          Wx::THE_APP.mainwindow.send(:add_map_to_hierarchy_control, map)
        end
        
      end
      
    end
    
  end
  
end