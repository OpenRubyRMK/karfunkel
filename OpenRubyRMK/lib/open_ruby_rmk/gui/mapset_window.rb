#!/usr/bin/env ruby
#Encoding: UTF-8

module OpenRubyRMK
  
  module GUI
    
    #This is the small window that displays the mapset you're using for a map. 
    class MapsetWindow < Wx::MiniFrame
      include Wx
      include R18n::Helpers
      
      def initialize(parent, mapset)
        super(parent, size: Size.new(260, 650), pos: Point.new(20, 20), title: "Test")
        self.background_colour = NULL_COLOUR
        
        @mapset = mapset
        
        create_menu
        create_controls
        setup_event_handlers
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
        @mapset_grid.table = MapsetTableBase.new(@mapset)
        @mapset_grid.evt_grid_select_cell{|event| @mapset_grid.refresh; event.skip}
      end
      
      def setup_event_handlers
        evt_menu(ID_CLOSE){close}
      end
      
    end
    
  end
  
end