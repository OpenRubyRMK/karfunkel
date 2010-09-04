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

      #A small terminal emulator control. It's not really sophisticated, but it's written as a 
      #control usable with wxRuby. 
      #
      #Please note that this class uses \\n for line breaks on every platform, just as it's superclass 
      #Wx::TextCtrl does. 
      #
      #There are two ways you can use this control. The easier one is just to create a new instance 
      #and then call #define_processing on it, which will associate the code block you pass it 
      #with the terminal. See #define_processing on how that exactly works. 
      #
      #The second possibility is to derive a control from Terminal, which gives you much more 
      #control over how processing takes place. You can override the methods that define the 
      #behaviour of the up and down arrow keys, the tabulator key and what happens when 
      #the user types "exit". This way, you could write a fully-featured terminal emulator. 
      #
      #Here's a simple example of usage: 
      #  @terminal = Terminal.new(self)
      #  @terminal.define_processing do |stdin, stdout, stderr|
      #    loop do
      #      stdout.print("Enter something: ")
      #      str = stdin.gets.chomp
      #      stdout.puts("You entered '#{str}'.")
      #    end
      #  end
      class Terminal < Wx::TextCtrl
        include Wx
        
        #IO object of a Terminal. If you write to such an IO, the written text will 
        #immediately appear on the terminal. If you read from it, you get back what the 
        #user entered followed by an [ENTER] keypress. 
        class TerminalIO < BasicObject
          
          #Creates a new TerminalIO. You shouldn't have to deal with this method, because 
          #it's called internally by the Terminal class. 
          #
          #+terminal+ is the terminal this IO is going to be associated with. 
          #+mode+ is the mode for the terminal-user, either :read or :write. 
          #The terminal itself can always write to a stream (there's no other way to 
          #get something into the input stream, right?)
          def initialize(terminal, mode)
            @terminal = terminal
            @mode = mode
            @in, @out = ::IO.pipe
          end
          
          #Human-readable description of form 
          #  <Terminal::TerminalIO (mode)>
          def inspect
            "<Terminal::TerminalIO (#{@mode})>"
          end
          
          #Internal method used by Terminal to write into the input stream. 
          def _terminal_write(str) # :nodoc:
            @out.write(str)
          end
          
          #Forward every method call to the unterlying IOs. 
          def method_missing(sym, *args, &block)
            stream = @mode == :read ? @in : @out
            return super unless stream.respond_to?(sym)
            
            ::Fiber.yield(true) if @mode == :read #Blocking IO operation follows. Resumed when the user presses [ENTER]. We yield true, because we use nil (result of a ended fiber) as an end condition. 
            ret = stream.send(sym, *args, &block)
            if @mode == :write
              append_ansi(read_all_from_io_unblocked(@in))
            end
            ret
          end
          
          private
          
          #Reads all available characters from +io+. Doesn't wait for EOF. 
          #
          #This method is only required, because Windows is appearently too stupid. 
          #It doesn't implement nonblocking IO. 
          def read_all_from_io_unblocked(io)
            str = ""
            if ::IO.select([io], nil, nil, 0) #Thank God that at least IO.select is implemented... ...and curse Ruby because it doesn't document the method!
              ::Kernel.loop do
                begin
                  ::Timeout.timeout(0.1){str << io.getc}
                rescue ::Timeout::Error
                  break
                end #begin
              end #loop
            end #if
            str
          end
          
          #This method appends the given text to the terminal. 
          #In future, it should provide processing of simple ANSI escape 
          #sequences like coloring. 
          def append_ansi(text)
            $log.debug("RMKonsole, appending '#{text}'.")
            @terminal.append_text(text)
            @terminal.set_insertion_point_end
            @terminal.update #Ensure Output of longer lasting operations gets visible
            @terminal.last_pos = @terminal.get_insertion_point
            @terminal.parent.refresh #A graphical error occurs without this line (some lines are displayed more than once). 
          end
          
        end
        
        #The default terminal style. It's the same as this combination: 
        #TE_PROCESS_ENTER | TE_PROCESS_TAB | TE_MULTILINE | TE_RICH | TE_NOHIDESEL | TE_CHARWRAP | SUNKEN_BORDER
        DEFAULT_TERMINAL_STYLE = TE_PROCESS_ENTER | TE_PROCESS_TAB | TE_MULTILINE | TE_RICH | TE_NOHIDESEL | TE_CHARWRAP | SUNKEN_BORDER
        
        #The terminal's input stream. You can read what the user enters from this. 
        #You should only call this inside #define_processing, beacuse it's likely to 
        #make your program wait for input infinitely otherwise. 
        attr_reader :stdin
        #The terminal's standard output. Write to this and it will appear in the terminal. 
        attr_reader :stdout
        #The terminal's standard error. Currently there's no difference to writing to +stdout+. 
        attr_reader :stderr
        #Used internally. The last position before a new command. 
        attr_accessor :last_pos
        
        #Creates a new Terminal object. +parent+ refers the this control's parent widnow (just as always) 
        #and +hsh+ is a hash taking several named parameters. They're the same as for a Wx::TextCtrl. 
        #
        #The control is disabled at first. Call #define_processing to enable it. 
        def initialize(parent, hsh = {})
          hsh[:style] ||= DEFAULT_TERMINAL_STYLE
          super(parent, hsh)
          
          self.foreground_colour = WHITE
          self.background_colour = BLACK
          self.font = Font.new(10, FONTFAMILY_TELETYPE, FONTSTYLE_NORMAL, FONTWEIGHT_NORMAL)
          
          #Position behind the last input. Used to get the text the user entered since the prompt was displayed. 
          @last_pos = 0
          
          @stdin = TerminalIO.new(self, :read)
          @stdout = TerminalIO.new(self, :write)
          @stderr = TerminalIO.new(self, :write)
          
          evt_key_down{|event| on_key_down(event)}
          evt_text_enter(self){|event| on_enter(event)}
          evt_left_down{|event| on_left_down(event)}
          
          #No processing has been defined yet, disable the control. 
          disable
        end
        
        #Defines the terminal's background process. You should implement a loop 
        #in it, because the terminal is disabled when the end of the execution is reached. 
        #To enable it again, you have to define a new process. 
        #
        #Note that the block you pass to this method is automatically stored inside a Fiber. 
        #Whenever you call a method on the standard input of the terminal (which is a blocking 
        #IO operation since the user hasn't entered something yet) the fiber is stopped and control 
        #returns to the GUI, allowing the user to type. When the user presses [ENTER], the entered 
        #text is extracted and written to the terminal's stdin, then the fiber is resumed. 
        #This has one major drawback: If the processing takes long, the whole GUI gets 
        #unresponsive, but since threads don't work correctly together with wxRuby, 
        #I didn't see another way. This process also implies that input always is line-buffered, so you cannot 
        #read a single character without having the user press enter. Use a real terminal emulator for that. 
        #
        #Here's a quick overview about how the processes evolves: 
        #1. You call #define_processing. The terminal is enabled, then your codeblock is stored inside a fiber. 
        #2. The fiber gets called. Since your fiber block hasn't entered it's mainloop yet, you can print a banner here or something like that. 
        #3. Your fiber block calls a method on the terminal's stdin. 
        #4. The fiber is stopped and control is returned to the GUI, allowing the user to satisfy your read request. 
        #5. The user enteres text and presses [ENTER]. 
        #6. The text the user entered (including the terminating newline) is written to the terminal's stdin. 
        #7. The fiber is resumed, and you can process what the user entered. 
        #8. The fiber reaches the last statement and exits. 
        #9. The terminal is cleared and disabled. The fiber gets deleted. 
        #Note, that you should implement a loop inside the block as I said earlier that ensures that the last statement of 7. returns back to 3. 
        #
        #This method yields the terminal's standard IO streams to it's block. 
        def define_processing(&block) # :yields: stdin, stdout, stderr
          #First, enable the control. 
          enable
          @fiber = Fiber.new{yield(@stdin, @stdout, @stderr)}
          #First resume, we want to display the prompt. 
          @fiber.resume
        end
        
        private
        
        #Ensures the user don't moves the cursor into what was already written. 
        #Calls the event hooks for the left, right and tab keys. 
        def on_key_down(event)
          case event.key_code
          when K_BACK
            event.skip unless get_insertion_point - 1 < @last_pos
          when K_LEFT
            event.skip unless get_insertion_point - 1 < @last_pos
          when K_UP
            on_up_arrow_down(event)
          when K_DOWN
            on_down_arrow_down(event)
          when K_TAB
            on_tab_down(event)
          else
            event.skip
          end
        end
        
        #Called when the user hits [ENTER] in the terminal. 
        #Writes the entered text to the terminal's stdin and ensures 
        #exiting if necessary. 
        def on_enter(event)
          append_text("\n")
          
          entered_text = get_range(@last_pos, get_last_position)
          @last_pos = get_last_position
          @stdin._terminal_write(entered_text)
          
          if entered_text.chomp == "exit"
            @fiber = nil
            return on_terminal_exit(nil)
          end
          
          #A previous call to a read operation from stdin stopped the fiber, so 
          #since new data is available now, we can resume it. 
          unless @fiber.resume #The fiber has ended
            @fiber = nil
            on_terminal_exit(nil)
          end
        end
        
        #This event handler just exists, because you could use the mouse 
        #to set the text insertion point somewhere into the already written output. 
        #It effectively blocks mouse usage except for the fact that a mouse click 
        #causes the Terminal to be focused. 
        def on_left_down(event)
          self.set_focus
        end
        
        #Called when the user presses the [UP] arrow key. Does nothing by default. 
        def on_up_arrow_down(event)
        end
        
        #Called when the user presses the [DOWN] arrow key. Does nothing by default. 
        def on_down_arrow_down(event)
        end
        
        #Called when the uses presses the [TAB] key. Does nothing by default. 
        def on_tab_down(event)
        end
        
        #Called when the user typed "exit" into the terminal. The default implementation 
        #clears the Terminal and disables it. 
        def on_terminal_exit(event)
          change_value("")
          disable
        end
        
      end
      
    end
    
  end
  
end