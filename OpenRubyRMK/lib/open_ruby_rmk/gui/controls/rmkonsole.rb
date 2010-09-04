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

#Monkeypatch IRB to make it able to interact with non-CUI inputs and outputs. 
#The original IRB code doesn't work with the global variables $stdin, $stdout and 
#$stderr if you're interesed. Instead, it converts STDIN and STDOUT 
#directly to file descriptors to which it connects via IO.open. This way, there's no 
#possibility to interact with IRB beside using the CUI. Due to this fact everybody 
#who wants IRB in a GUI has to monkeypatch it like we did here. 
module IRB
  
  class Context
    #Needed for the modifcation of class Irb. 
    attr_reader :output_method
    
    alias _old_prompting? prompting?
    #This method checks wheather we're reading from STDIN by default which 
    #is quite wrong at our place, since we read from a GUI control. Allow reading from 
    #my own InputMethod. 
    def prompting?
      ret = _old_prompting?
      ret || @io.kind_of?(TerminalInputMethod)
    end
    
  end
  
  #Everything that outputs in class IRB writes to $stdout by default--since our 
  #output is a GUI control, defined by an OutputMethod, we have to 
  #overwrite the methods that IRB uses for outputting. 
  class Irb
    
    #Redirect output to the given output method. 
    def print(*args)
      @context.output_method.print(*args)
    end
    
    #Redirect output to the given output method. 
    def printf(*args)
      @context.output_method.printf(*args)
    end
    
  end
  
  #Starts IRB to read from and write to the given input/output methods. 
  #The last parameter is the object IRB will use as the toplevel namespace, a module for example. 
  #Pass nil to get it from TOPLEVEL_BINDING. 
  def IRB.start_external(input_method, output_method, main = nil)
    IRB.setup(nil)
    
    ws = main ? WorkSpace.new(main) : nil
    irb = Irb.new(ws, input_method, output_method)
    
    @CONF[:IRB_RC].call(irb.context) if @CONF[:IRB_RC]
    @CONF[:MAIN_CONTEXT] = irb.context
    trap("SIGINT") do
      irb.signal_handle
    end
    
    catch(:IRB_EXIT) do
      irb.eval_input
    end
    #print "\n"
  end
  
end

#Read from a Terminal control. The methods in this class just reflect what IRB's standard 
#StdioInputMethod does, beside ::new. 
class TerminalInputMethod < IRB::InputMethod
  
  #Creates a new TerminalInputMethod. Pass in the terminal you want to connect to. 
  def initialize(terminal)
    super()
    @line_no = 0
    @line = []
    @terminal = terminal
  end
  
  def gets
    @terminal.stdout.print @prompt
    line = @terminal.stdin.gets
    @line[@line_no += 1] = line
  end
  
  def eof?
    false
  end
  
  def readable_after_eof?
    true
  end
  
  def line(line_no)
    @line[line_no]
  end
  
  #wxRuby always works with UTF-8. 
  def encoding
    Encoding.find("UTF-8")
  end
end

#Write to a Terminal. 
class TerminalOutputMethod < IRB::OutputMethod
  
  #Creates a new TerminalOutputMethod. 
  def initialize(terminal)
    super()
    @terminal = terminal
  end
  
  def print(*opts)
    @terminal.stdout.print(*opts)
  end
  
end

module OpenRubyRMK
  
  module GUI
    
    module Controls
      
      #The terminal control you type into when using OpenRubyRMKonsole. 
      class RMKonsole < Terminal
        
        #A typical wxRuby control initializer. The hash takes an additional :main parameter which 
        #describes the object in whose scope you want to execute IRB, i.e., IRB's "main" object. 
        #If not specified, it will be set to the default main object. 
        def initialize(parent, hsh = {})
          super(parent, hsh.reject{|k, v| k == :main}) #wxRuby complains on unknown keys
          
          define_processing do |stdin, stdout, stderr|
            stdout.write(OpenRubyRMKonsole::BANNER)
            loop do
              IRB.start_external(TerminalInputMethod.new(self), TerminalOutputMethod.new(self), hsh[:main])
            end
          end
          
        end
        
        #We close the parent window if the user enteres "exit". 
        def on_terminal_exit(event)
          parent.close
        end
        
      end
      
    end
    
  end
  
end