#!/usr/bin/env ruby
#Encoding: UTF-8

module OpenRubyRMK
  
  module GUI
    
    module Windows
      
      class ThreadedProgressDialog < Wx::ProgressDialog
        include Wx
        
        def initialize(*args, &block)
          super(*args)
          @block = block
          @timer = Timer.every(10){Thread.pass}
          Thread.new{@block.call(self)}
        end
        
        def update(percent, newmsg = "")
          @timer.stop if percent >= 100
          super
        end
        
      end
      
    end
    
  end
  
end