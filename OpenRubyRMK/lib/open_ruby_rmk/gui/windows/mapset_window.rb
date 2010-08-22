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
        
        #Creates a new MapsetWindow. The window is disabled at the beginning, 
        #allowing to show and hide a single instance without the need to create 
        #new ones all the time. 
        #Call #reload to enable everything. 
        def initialize(parent)
          super(parent, size: Size.new(260, 650), pos: Point.new(20, 20), title: t.window_titles.mapset_window)
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
          @mapset_grid.register_data_type(GRID_FIELD_TYPE, FieldRenderer.new, GridCellTextEditor.new)
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