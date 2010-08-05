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

module OpenRubyRMK
  
  class Mapset
    
    attr_reader :filename
    
    def self.load(filename)
      obj = allocate
      obj.instance_eval do
        @filename = Pathname.new(filename)
      end
      obj
    end
    
    def ==(other)
      @filename == other.filename
    end
    
  end
  
end