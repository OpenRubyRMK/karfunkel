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
    
    #This class is used to render Grid cells of type "MAP_FIELD". Since it's not possible to inherit 
    #from GridCellRenderer, I had to chose a subclass and inherit from that one. This has a fatal side effect: 
    #I can't call +super+ in the #draw method, because I had to supply a "STRING" type. However, without calling 
    #+super+, rendering problems arise if the Grid's cells are not exactly the same size as the mapset's fields. Try it out: 
    #Just uncomment in "mapset_window.rb" the lines that forbid you to resize columns and rows (#create_controls method), and then do 
    #the forbidden thing... :-(
    class FieldRenderer < Wx::GridCellStringRenderer
      
      #Displays the data for the specified cell. Note that I do not call 
      #+super+, since this class is derived from +GridCellStringRenderer+, which 
      #expects "STRING" types. 
      def draw(grid, attr, dc, rect, row, col, is_selected)
        img = grid.table.get_value(row, col)
        bmp = Wx::Bitmap.from_image(img)
        dc.draw_bitmap(bmp, rect.x, rect.y, true)
      end
      
    end
    
  end
  
end