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
      
      #This class is probably that one you most interact with when creating a 
      #game with OpenRubyRMK. It represents the map grid, that is, the tabular 
      #editing field using the most space on the GUI's surface. 
      #
      #A MapGrid is a customized Wx::Grid control, where the biggest customization 
      #is the table base.  With an added "MAP_FIELD" type and a fitting renderer, 
      #this class is able to display the single fields. 
      #
      #Note that when changing values of the MapGrid, you can't use the regular wxRuby 
      #method Grid#set_cell_value, since that one just deals with "STRING" types. Instead, 
      #call #table on the MapGrid and then retrieve the field you want to change from it. 
      #Afterwards, do your changes, and you're done. 
      #  Wx::THE_APP.mainwindow.instance_eval do
      #    #Find out on which map we work at the moment
      #    active_map = THE_APP.selected_map
      #    #Retrieve the map field at the wanted position ((0|0) in this case). 
      #    #Note that you have to specify the position in [row, col] form, not [x, y]!!
      #    field = @map_grid.get_value(0, 0)
      #    #Use another image from the mapset
      #    field.reassign_image(12, 7) #Field (12|7) from the mapset ([x, y] argument form!!)
      #    #Done. No need to call #set_value on the table, since the table 
      #    #holds a reference to the field, so we referenced the exact same field as 
      #    #the table above. 
      #  end
      #
      #Since the MapGrid is, as I just said, frequently used it has the ability to perform 
      #different actions on equal user input, depending on in which _mode_ the grid is. 
      #The mode is just an instance variable called <tt>@mode</tt> with corresponding 
      ##mode and #mode= methods. The default mode is 'paint mode' and the list of 
      #possible modes you can assing to the +mode+ attribute is currently (each is a symbol): 
      #[:erase] Delete mode, in which user clicks clean fields. 
      #[:paint] Paint mode, in which user clicks cause mapset fields placed on the map. 
      class MapGrid < Wx::Grid
        include Wx
        
        #This is the grid cell type for a field on the map. If you retrieve such a type from 
        #a grid, the cell's value will be a OpenRubyRMK::MapField object. 
        MAP_FIELD_TYPE = "MAP_FIELD".freeze
        
        #An array containing a list of all possible modes the MapGrid 
        #can be set to. However, if you write *really* sophisticated plugins that 
        #add completely new actions to the core user interface, you may 
        #add a new mode here. But if you do so, you should 
        #probably think about putting the action in the main code 
        #and submit a patch to the OpenRubyRMK Team. 
        MODES = [:paint, :erase]
        
        #Table base class for the map. Since OpenRubyRMK essentially creates 2D games, 
        #the Z coordinate of maps is displayed by a trick: Instead of creating a 3D table 
        #(which wxRuby isn't able to) we just define a kind of "working" layer. By assigning 
        #the +z+ attribute of the table base you change the "layer" on which fields are placed. 
        class MapTableBase < Wx::GridTableBase
          
          #The Z layer we act upon at the moment. Automatically set by the MapGrid in 
          #the MapGrid#z= method (which is hidden in the +z+ attribute). 
          attr_accessor :z
          
          #Creates a new MapTableBase. Pass in the Map you want this table to be fore. 
          def initialize(map)
            super()
            @map = map
            @z = 0
          end
          
          #The map's height. 
          def get_number_rows
            @map.height
          end
          
          #The map's width. 
          def get_number_cols
            @map.width
          end
          
          #Returns a MapField object for the given position. Please note 
          #that the position is given in row-col form, which is reversed compared 
          #to the typical x-y form. 
          def get_value(row, col)
            @map[col, row, @z]
          end
          
          #Sets the MapField object for the given position. Please note 
          #that the position is given in row-col form, which is reversed compared 
          #to the typical x-y form. 
          def set_value(row, col, value)
            @map[col, row, @z] = value
          end
          
          #Returns the type of the given cell, which should always 
          #be MAP_FIELD_TYPE for this class's instances. 
          def get_type_name(row, col)
            MAP_FIELD_TYPE
          end
          
          #Returns the Wx::GridCellAttr of the given cell. 
          def get_attr(row, col, attr_kind)
            attr = Wx::GridCellAttr.new
            attr
          end
          
          #true if really nothing is placed on the cell. No field image, 
          #no characters. 
          def is_empty_cell(row, col)
            @map[col, row, @z].clear?
          end
          
        end
        
        #This renderer displays grid cells of type MAP_FIELD_TYPE, making 
        #it the normal renderer for maps. See MapsetWindow::MapsetFieldRenderer 
        #for an explanation of some abnorm things. 
        class MapFieldRenderer < Wx::GridCellStringRenderer
          
          #Displays the data for the specified cell. 
          def draw(grid, attr, dc, rect, row, col, is_selected)
            super
            field = grid.table.get_value(row, col)
            bmp = Wx::Bitmap.from_image(field.image)
            dc.draw_bitmap(bmp, rect.x, rect.y, true)
            if is_selected
              dc.pen = Wx::Pen.new(Wx::RED, 1)
              dc.brush = Wx::Brush.new(Wx::BLUE, Wx::CROSSDIAG_HATCH)
              dc.draw_rectangle(rect.x, rect.y, rect.width, rect.height)
              dc.pen = Wx::NULL_PEN
              dc.brush = Wx::NULL_BRUSH
            end
          end
          
        end
        
        ##
        # :attr_accessor: z
        #The "layer" we're currently working on. When fields are 
        #changed by the user, only the fields on this layer are affected. 
        #The ground layer is 0. 
        
        ##
        # :attr_accessor: mode
        #The MapGrid can enter several modes in which user actions 
        #cause different code to run. For example, there is a 'paint mode' 
        #in which the user may put any mapset fields he wants on the map 
        #or a 'delete mode' in which fields are deleted from the map. 
        #
        #The list of possible modes can be found in this class's documentation. 
        
        #Creates a new MapGrid. Parameters are the same as for Wx::Grid. 
        def initialize(parent, hsh = {})
          super
          self.default_col_size = Mapset::FIELD_EDGE
          self.default_row_size = Mapset::FIELD_EDGE
          self.disable_drag_col_size
          self.disable_drag_row_size
          self.register_data_type(MAP_FIELD_TYPE, MapFieldRenderer.new, GridCellTextEditor.new)
          
          @mode = :paint
          @z = 0
          
          #TODO: Wx::Grids don't receive motion events!
          #~ evt_left_down{|event| on_left_down(event)}
          #~ evt_motion{|event| on_motion(event)}
          evt_key_down{|event| on_key_down(event)}
        end
        
        #See accessor. 
        def mode # :nodoc:
          @mode
        end
        
        #See accessor. 
        def mode=(val) # :nodoc:
          raise(ArgumentError, "Invalid mode #{val.inspect}!") unless MODES.include?(val)
          @mode = val
        end
        
        #See accessor. 
        def z # :nodoc:
          @z
        end
        
        #See accessor. 
        def z=(val) # :nodoc:
          raise(RangeError, "Index #{val} out of range!") if val < 0
          self.table.z = val
          @z = val
        end
        
        private
        
        #Returns an array of all selected cells, i.e. block selected, sequence selection or, 
        #if no selection was made, the currently selected cell. The form is: 
        #  [ [row, col], [row, col], ...]
        def get_all_selected_cells
          cells = []
          #Handling of block selections
          row1, col1 = selection_block_top_left.flatten #For a reason I don't know, these two methods...
          row2, col2 = selection_block_bottom_right.flatten #...returns 2-dimensional arrays of form [[x, y]]. BUG??
          unless [row1, col1, row2, col2].any?{|obj| obj.nil?} #No block selection if true
            row1.upto(row2) do |row|
              col1.upto(col2) do |col|
                cells << [row, col]
              end
            end
          end
          
          #Handling of sequence selections (those made via holding down [CTRL] key)
          cells.concat(get_selected_cells)
          
          #If no "big" selection was done, apply to a single cell
          cells << [get_grid_cursor_row, get_grid_cursor_col] if cells.empty?
          cells
        end
        
        #Changes the image of all given cells into that one of the currently 
        #selected field of the mapset. No other field properties are changed. 
        def draw_fields(positions)
          positions.each do |row, col|
            field = self.table.get_value(row, col)
            field.reassign_image(*THE_APP.selected_mapset_field)
            #No need to call table.set_value here since the table holds the 
            #same reference to the MapField object as I do in the above code. 
          end
        end
        
        #Changes the image of all given cells into the transparent null image. 
        #This does not affact any other properties (such as the characters for example) 
        #in any way. 
        def delete_fields(positions)
          positions.each do |row, col|
            field = self.table.get_value(row, col)
            field.clear_image!
            #No need to call table.set_value here, see #draw_fields for an explanation. 
          end
        end
        
        #Associates special keystrokes with further event processing methods. 
        #Events are only #skip-ped automatically for keystrokes not associated 
        #with another handler method. 
        def on_key_down(event)
          case event.key_code
            when K_RETURN, K_NUMPAD_ENTER then on_enter_down(event)
          else
            event.skip
          end
        end
        
        def on_enter_down(event)
          case @mode
            when :paint then draw_fields(get_all_selected_cells)
            when :erase then delete_fields(get_all_selected_cells)
          end
          event.skip
        end
        
        #TODO: Wx::Grids don't receive motion events!
        #~ #Skip left down events in painting mode. 
        #~ def on_left_down(event)
          #~ event.skip unless @paint_mode
        #~ end
        
        #TODO: Wx::Grids don't receive motion events!
        #~ #If in painting mode, cause drawing. 
        #~ def on_motion(event)
          #~ return unless @paint_mode
          #~ return unless event.left_is_down
          #~ #Convert cursor position into row and col
          #~ pos = [y_to_row(event.y), x_to_row(event.x)]
          #~ return if pos.any?{|p| p == NOT_FOUND}
          #~ #Assign new image DEBUG: Get selected mapset image!!
          #~ field = get_value(*pos)
          #~ field.reassign_image(1, 0)
        #~ end
        
      end
      
    end
    
  end
  
end