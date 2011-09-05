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
  
  module Karfunkel
  
    module ProjectManagement
    
      class Character
      
        attr_accessor :code
        attr_reader :graphic_filename
        attr_reader :x
        attr_reader :y
        
        def self.load(x, y, graphic_filename)
          char = allocate
          char.instance_eval do
            @x, @y = x, y
            @graphic_filename = Pathname.new(graphic_filename)
            @code = ""
          end
          char
        end
        
        def initialize
          #TODO
        end
        
      end
      
    end
    
  end
  
end