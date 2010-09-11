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
      
      #In this window everything known about a map is displayed. 
      class PropertiesWindow < Wx::MiniFrame
        include Wx
        include R18n::Helpers
        
        #Creates a new PropertiesWindow. The window is disabled at the beginning, allowing 
        #to show and hide a single instance rather than creating and destroying new ones all the time. 
        #Call #reload to enable the window. 
        #
        #Please also note that you have to call #on_change before you can show the window. 
        def initialize(parent)
          super(parent, size: Size.new(300, 300), pos: Point.new(*OpenRubyRMK.config["startup_map_properties_pos"]), title: t.window_titles.properties_window)
          self.background_colour = NULL_COLOUR
          
          @map = nil
          @available_mapsets = nil
          @something_changed = false
          @block = nil
          
          create_controls
          make_sizers
          setup_event_handlers
          
          #Only a call to #reload can enable the window
          self.disable
        end
        
        #Pass this method a block you want to be called every time the user confirms 
        #his or her changements. 
        def on_change(&block)
          @block = block
        end
        
        #Shows this window. Implementation is as in the superclass, just a check for 
        #the code block passed to #on_change is done. 
        def show(*)
          Kernel.raise(ArgumentError, "No on_change block passed!") unless @block
          super
        end
        
        #Refreshes all internal data and enables the window. If you pass +nil+ for 
        #+map+, the inverse happens: The window is disabled. 
        def reload(map, available_mapsets)
          @map = map
          @available_mapsets = available_mapsets
          
          if @map.nil?
            self.disable
            return
          end
          self.enable
          
          @map_name_txt.value = @map.name
          @parent_id_txt.value = @map.has_parent? ? @map.parent.id.to_s : "0"
          @map_id_txt.value = @map.id.to_s
          @mapset_drop.clear
          @available_mapsets.each{|mapset| @mapset_drop.append(mapset.filename.basename.to_s)}
          @width_spin.value = @map.width
          @height_spin.value = @map.height
          @depth_spin.value = @map.depth
          
          @mapset_drop.selection = @available_mapsets.index(@map.mapset)
          #Undo setting of @something_changed and the button, which are both 
          #triggered by the above operations. 
          @something_changed = false
          @ok_button.disable
        end
        
        private
        
        def create_controls
          @map_name_txt = TextCtrl.new(self)
          @parent_id_txt = TextCtrl.new(self)
          @map_id_txt = TextCtrl.new(self)
          @mapset_drop = Choice.new(self)
          @width_spin = SpinCtrl.new(self, min: 20, max: 999)
          @height_spin = SpinCtrl.new(self, min: 15, max: 999)
          @depth_spin = SpinCtrl.new(self, min: 3, max: 999)
          @ok_button = Button.new(self, id: ID_OK, label: "OK")
          
          @parent_id_txt.disable #Neither this nor the next one...
          @map_id_txt.disable #...is editable after map creation. 
          @ok_button.disable #Only clickable after something has changed
        end
        
        def make_sizers
          #Preparation
          top_sizer = VBoxSizer.new
          top_sizer.add_spacer(20)
          
          
          #Row 1
          h_sizer = HBoxSizer.new
          v_sizer = VBoxSizer.new
          h_sizer.add_spacer(20)
          v_sizer.add_item(StaticText.new(self, label: t.dialogs.map_dialog.map_name))
          v_sizer.add_item(@map_name_txt, proportion: 1, flag: EXPAND)
          h_sizer.add_item(v_sizer, proportion: 3)
          
          h_sizer.add_spacer(20)
          
          v_sizer = VBoxSizer.new
          v_sizer.add_item(StaticText.new(self, label: t.dialogs.map_dialog.parent_id))
          v_sizer.add_item(@parent_id_txt, proportion: 1, flag: EXPAND)
          h_sizer.add_item(v_sizer, proportion: 1)
          h_sizer.add_spacer(20)
          top_sizer.add_item(h_sizer, flag: EXPAND)
          
          top_sizer.add_spacer(20)
          
          #Row 2
          h_sizer = HBoxSizer.new
          v_sizer = VBoxSizer.new
          h_sizer.add_spacer(20)
          v_sizer.add_item(StaticText.new(self, label: t.dialogs.map_dialog.map_id))
          v_sizer.add_item(@map_id_txt, proportion: 1, flag: EXPAND)
          h_sizer.add_item(v_sizer, proportion: 1)
          
          h_sizer.add_spacer(20)
          
          v_sizer = VBoxSizer.new
          v_sizer.add_item(StaticText.new(self, label: t.dialogs.map_dialog.mapset))
          v_sizer.add_item(@mapset_drop, proportion: 1, flag: EXPAND)
          h_sizer.add_item(v_sizer, proportion: 1)
          h_sizer.add_spacer(20)
          top_sizer.add_item(h_sizer, flag: EXPAND)
          
          top_sizer.add_spacer(20)
          
          #Row 3
          h_sizer = HBoxSizer.new
          v_sizer = VBoxSizer.new
          h_sizer.add_spacer(20)
          v_sizer.add_item(StaticText.new(self, label: t.general.often_used.width))
          v_sizer.add_item(@width_spin, proportion: 1, flag: EXPAND)
          h_sizer.add_item(v_sizer, proportion: 1)
          
          h_sizer.add_spacer(20)
          
          v_sizer = VBoxSizer.new
          v_sizer.add_item(StaticText.new(self, label: t.general.often_used.height))
          v_sizer.add_item(@height_spin, proportion: 1, flag: EXPAND)
          h_sizer.add_item(v_sizer, proportion: 1)
          
          h_sizer.add_spacer(20)
          
          v_sizer = VBoxSizer.new
          v_sizer.add_item(StaticText.new(self, label: t.general.often_used.depth))
          v_sizer.add_item(@depth_spin, proportion: 1, flag: EXPAND)
          h_sizer.add_item(v_sizer, proportion: 1)
          h_sizer.add_spacer(20)
          top_sizer.add_item(h_sizer, flag: EXPAND)
          
          top_sizer.add_spacer(20)
          
          #Buttons
          sizer = StdDialogButtonSizer.new
          sizer.add_button(@ok_button)
          sizer.realize
          top_sizer.add_item(sizer)
          
          self.sizer = top_sizer
        end
        
        def setup_event_handlers
          evt_close{|event| self.hide; event.veto} #We don't close the window, we just hide it
          evt_text(@map_name_txt){|event| on_val_changed(event)}
          evt_combobox(@mapset_drop){|event| on_val_changed(event)}
          evt_spinctrl(@width_spin){|event| on_val_changed(event)}
          evt_spinctrl(@height_spin){|event| on_val_changed(event)}
          evt_spinctrl(@depth_spin){|event| on_val_changed(event)}
          evt_button(@ok_button){|event| on_button_clicked(event)}
        end
        
        def on_val_changed(event)
          @ok_button.enable
        end
        
        def on_button_clicked(event)
          @map.name = @map_name_txt.value.to_s
          @map.mapset = Mapset.load(@mapset_drop.string_selection)
          @map.width = @width_spin.value
          @map.height = @height_spin.value
          @map.depth = @depth_spin.value
          
          self.title = @map.name
          @ok_button.disable
          
          @block.call(@map)
        end
        
      end #PropertiesWindow
      
    end #Windows
    
  end #GUI
  
end #OpenRubyRMK
