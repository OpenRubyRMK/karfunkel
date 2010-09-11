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
    
    module Windows
      
      #This is the small window that displays the mapset you're using for a map. 
      class MapsetWindow < Wx::MiniFrame
        include Wx
        include R18n::Helpers
        
        #The grid cell type used for mapset fields. 
        MAPSET_FIELD_TYPE = "MAPSET_FIELD".freeze
        
        #According to the wxRuby docs, a GridTableBase is the "database" of a Grid. 
        #Following this explanation, this class supploes the Grid control used in the 
        #mapset window with data, i.e. with images based on the underlying mapset. 
        #
        #The relationships are as follows: 
        #A Grid control gets it's data from the associated GridTableBase. The data 
        #is displayed via a per-cell renderer which is found out by querying the GridTableBase 
        #for a cell's type. For our example, MapsetTableBase will return "MAP_FIELD" as the type 
        #which in turn can be rendered by the FieldRenderer class. 
        class MapsetTableBase < Wx::GridTableBase
          include Wx
          
          #The mapset associated with this GridTableBase. 
          attr_reader :mapset
          
          #Creates a new "database". Pass in the mapset you want to display. 
          def initialize(mapset)
            super()
            @mapset = mapset
          end
          
          #The height of the mapset. 
          def get_number_rows
            @mapset.rows
          end
          
          #The mapset's width. 
          def get_number_cols
            @mapset.columns
          end
          
          #Returns the Wx::Image for the given positon. Note that this 
          #method takes the position in <tt>[row, col]</tt> form instead 
          #of the usual <tt>[x, y]</tt> one, effectively inverting the 
          #argument chain. 
          def get_value(row, col)
            @mapset[col, row] #method takes [x, y]
          end
          
          #Should always return MapsetWindow::MAPSET_FIELD_TYPE. 
          def get_type_name(row, col)
            MAPSET_FIELD_TYPE
          end
          
          #Retrieves the attributes of the given cell. 
          #Note that all cells of this table are read-only. 
          def get_attr(row, col, attr_kind)
            attr = GridCellAttr.new
            attr.read_only = true
            attr
          end
          
          #No cells are empty in this grid, only transparent. 
          #This means, this method always returns false. 
          def is_empty_cell(row, col)
            false #No empty cells - even transparent ones contain something. 
          end
          
        end
        
        #This class is used to render Grid cells of type "MAP_FIELD". Since it's not possible to inherit 
        #from GridCellRenderer, I had to chose a subclass and inherit from that one. As I chose the 
        #string renderer, wxRuby now expects me to return strings form my grid which isn't possible since 
        #I don't manage strings, but Wx::Images. I could leave out the call to +super+ in the #draw method, 
        #but the parent method does some important prepartion I don't want to skip. I chose the other way: 
        #In application.rb I monkeypatched Wx::Image to have a #to_str method that returns an empty 
        #string. Not nice, but it works. 
        class MapsetFieldRenderer < Wx::GridCellStringRenderer
          
          #Displays the data for the specified cell. 
          def draw(grid, attr, dc, rect, row, col, is_selected)
            super
            img = grid.table.get_value(row, col)
            bmp = Wx::Bitmap.from_image(img)
            dc.draw_bitmap(bmp, rect.x, rect.y, true)
          end
          
        end
        
        #Creates a new MapsetWindow. The window is disabled at the beginning, 
        #allowing to show and hide a single instance without the need to create 
        #new ones all the time. 
        #Call #reload to enable everything. 
        def initialize(parent)
          super(parent, size: Size.new(260, 650), pos: Point.new(*OpenRubyRMK.config["startup_mapset_pos"]), title: t.window_titles.mapset_window)
          self.background_colour = NULL_COLOUR
          
          @mapset = nil
          
          create_menu
          create_controls
          setup_event_handlers
          
          #Only a call to #reload can enable the window
          self.disable
        end
        
        #Reloads all internal data from the given mapset and enables 
        #the window. If you pass +nil+, it will be disabled. 
        def reload(mapset)
          @mapset = mapset
          
          if @mapset.nil?
            self.disable
            return
          end
          self.enable
          
          @mapset_grid.table = MapsetTableBase.new(@mapset)
        end
        
        #Returns the position of the field that is currently selected on the mapset. 
        #This is a two-element array of form
        #  [x, y]
        #. Note that this doesn't contain any information on the mapset itself--if you 
        #want to get informed about the used mapset, call 
        #  Wx::THE_APP.selected_map.mapset
        #. 
        def selected_field
          [@mapset_grid.grid_cursor_col, @mapset_grid.grid_cursor_row]
        end
        
        private
        
        def create_menu
          @menu_bar = MenuBar.new
          @menus = {}
          
          @menus[:file] = Menu.new
          @menus[:file].append(ID_CLOSE, t.menus.mapset_window.file.close.name)
          @menu_bar.append(@menus[:file], t.menus.mapset_window.file.name)
          
          self.menu_bar = @menu_bar
        end
        
        def create_controls
          @mapset_grid = Grid.new(self)
          @mapset_grid.default_col_size = Mapset::FIELD_EDGE
          @mapset_grid.default_row_size = Mapset::FIELD_EDGE
          @mapset_grid.disable_drag_col_size
          @mapset_grid.disable_drag_row_size
          @mapset_grid.col_label_size = 0
          @mapset_grid.row_label_size = 0
          @mapset_grid.register_data_type(MAPSET_FIELD_TYPE, MapsetFieldRenderer.new, GridCellTextEditor.new)
        end
        
        def setup_event_handlers
          evt_close{|event| self.hide; event.veto}
          evt_menu(ID_CLOSE){close}
          @mapset_grid.evt_grid_select_cell{|event| @mapset_grid.refresh; event.skip}
        end
        
      end #MapsetWindow
      
    end #Windows
    
  end #GUI
  
end #OpenRubyRMK