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
  
  module GUI
    
    module Controls
      
      #Everybody likes terminals, so OpenRubyRMK comes with one as well!
      class Terminal < Wx::TextCtrl
        include Wx
        
        #The default terminal style. It's the same as this combination: 
        #TE_PROCESS_ENTER | TE_MULTILINE | TE_RICH | TE_NOHIDESEL | TE_CHARWRAP | SUNKEN_BORDER | ALWAYS_SHOW_SB
        DEFAULT_TERMINAL_STYLE = TE_PROCESS_ENTER | TE_MULTILINE | TE_RICH | TE_NOHIDESEL | TE_CHARWRAP | SUNKEN_BORDER | VSCROLL | ALWAYS_SHOW_SB
        
        #Creates a new Terminal object. +parent+ refers the this control's parent widnow (just as always) 
        #and +hsh+ is a hash taking several named parameters. They're the same as for a Wx::TextCtrl, except 
        #for the default :style. 
        def initialize(parent, hsh = {})
          hsh[:style] ||= DEFAULT_TERMINAL_STYLE
          super(parent, hsh.reject{|key, value| key == :prompt || key == :process})
          
          self.foreground_colour = WHITE
          self.background_colour = BLACK
          self.font = Font.new(10, FONTFAMILY_TELETYPE, FONTSTYLE_NORMAL, FONTWEIGHT_NORMAL)
          
          @exit = false
          #Position behind the last prompt. Used to get the text the user entered since the prompt was displayed. 
          @last_pos = 0
          #The history of entered commands. The first entry is the "search index" which 
          #is incremented and decrimented when the user presses the up and down arrow keys 
          #and will always stay negative, allowing us to reversely search through the command 
          #history (due to the fact negative indices count from the end) without the need to call 
          ##reverse which may be slow on large arrays. 
          @command_history = [0, [""]]
          
          @in_io = StringIO.new("", "r+")
          @out_io = StringIO.new("", "w+")
          @err_io = StringIO.new("", "w+")
          
          change_value(OpenRubyRMKonsole::BANNER)
          display_prompt
          
          evt_key_down{|event| on_key_down(event)}
          evt_text_enter(self){|event| on_enter(event)}
          evt_left_down{|event| on_left_down(event)}
        end
        
        def finished?
          @exit
        end
        
        private
        
        #Implements the command history browsing and 
        #ensures that we don't move the cursor into older output 
        #or the prompt. 
        def on_key_down(event)
          case event.key_code
          when K_BACK
            event.skip unless get_insertion_point - 1 < @last_pos
          when K_LEFT
            event.skip unless get_insertion_point - 1 < @last_pos
          when K_UP
            @command_history[0] -= 1
            reconstruct_command
          when K_DOWN
            @command_history[0] += 1
            reconstruct_command
          else
            event.skip
          end

        end
        
        #Triggers command execution, followed by a new prompt. 
        def on_enter(event)
          process_input
          display_prompt
        end
        
        #This event handler just exists, because you could use the mouse 
        #to set the text insertion point somewhere into the already written output. 
        #It effectively blocks mouse usage except for the fact that a mouse click 
        #causes the Terminal to be focused. 
        def on_left_down(event)
          self.set_focus
        end
        
        #Displays a new prompt. 
        def display_prompt
          new_val = self.value + "#{Dir.pwd}|RMK> "
          change_value(new_val)
          set_insertion_point_end
          @last_pos = get_insertion_point
        end
        
        #Processes what the user has typed in since the prompt has been displayed. 
        def process_input
          new_val = self.value + "\n"
          change_value(new_val)
          
          @in_io.reopen("", "r+")
          @out_io.reopen("", "w+")
          @err_io.reopen("", "w+")
          
          cmd = get_range(@last_pos, get_last_position)
          
          prev_in_pos = @in_io.pos
          @in_io.write(cmd)
          @in_io.pos = prev_in_pos
          
          
          #~ new_val += execute_command(cmd)
          prev_out_pos = @out_io.pos
          prev_err_pos = @err_io.pos
          
          execute_command
          @command_history.last << cmd.chomp
          @command_history[0] = 0
          
          @out_io.pos = prev_out_pos
          @err_io.pos = prev_err_pos
          new_val += @out_io.read
          new_val += @err_io.read
          change_value(new_val)
        end
        
        #This method browses the command history. 
        def reconstruct_command
          #Don't get greater than 0 - we use Ruby's negative index feature
          @command_history[0] = 0 if @command_history[0] > 0
          #Ensure we don't grab indices that don't exist, -5 for a three-command array plus empty string for example. 
          #The complicated setting construct is required since the index is not allowed to get positive. 
          @command_history[0] = -@command_history[1].size + 1 if -@command_history[0] >= @command_history[1].size
          #Get everything till the last displayed prompt and append the reconstructed command
          new_val = self.get_range(0, @last_pos) + @command_history[1][@command_history[0]]
          change_value(new_val)
          set_insertion_point_end
        end
        
        #Executes the given command line. 
        def execute_command
          cmd = @in_io.gets.chomp.split
          return "\n" if cmd.empty? #User entered empty command line
          
          $stdin = @in_io
          $stdout = @out_io
          $stderr = @err_io
          begin
            if cmd[0] == "exit"
              @exit = true
              puts "Exiting..."
            elsif OpenRubyRMKonsole::Commands.respond_to?(cmd[0])
              OpenRubyRMKonsole::Commands.send(cmd[0], *cmd.drop(1))
            else
              puts "Unknown command '#{cmd[0]}'."
            end
          rescue => e
            $stderr.puts(e.message)
          ensure
            $stdin = STDIN
            $stdout = STDOUT
            $stderr = STDERR
          end
        end
        
      end #Terminal
      
    end #Controls
    
  end #GUI
  
end #OpenRubyRMK