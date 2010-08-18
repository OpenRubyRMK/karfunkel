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
      
      class NewMapDialog < Wx::Dialog
        include Wx
        include R18n::Helpers
        
        attr_reader :map
        
        def initialize(parent, hsh)
          super(parent, title: t.dialogs.map_dialog.title_new, size: Size.new(400, 250))
          raise(ArgumentError, "No mapsets specified!") unless hsh.has_key?(:available_mapsets)
          @opts = hsh
          @map = nil
          
          create_controls
          make_sizers
          setup_event_handlers
        end
        
        private
        
        def create_controls
          id = @opts.has_key?(:id) ? @opts[:id] : Map.next_free_id
          
          @map_name_txt = TextCtrl.new(self, value: @opts.has_key?(:name) ? @opts[:name] : "Map-#{id}")
          @parent_id_txt = TextCtrl.new(self, value: @opts.has_key?(:parent_id) ? @opts[:parent_id].to_s : "0")
          @map_id_txt = TextCtrl.new(self, value: id.to_s)
          @mapset_drop = Choice.new(self, choices: @opts[:available_mapsets].map{|map| map.filename.basename.to_s})
          @width_spin = SpinCtrl.new(self, initial: @opts.has_key?(:width) ? @opts[:width] : 20, min: 20, max: 999)
          @height_spin = SpinCtrl.new(self, initial: @opts.has_key?(:height) ? @opts[:height] : 15, min: 15, max: 999)
          @depth_spin = SpinCtrl.new(self, initial: @opts.has_key?(:depth) ? @opts[:depth] : 3, min: 3, max: 999)
          @ok_button = Button.new(self, id: ID_OK, label: "OK")
          @cancel_button = Button.new(self, id: ID_CANCEL, label: "Cancel")
          
          @mapset_drop.selection = 0 #Automatically preselect the first entry
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
          sizer.add_button(@cancel_button)
          sizer.realize
          top_sizer.add_item(sizer)
          
          self.sizer = top_sizer
        end
        
        def setup_event_handlers
          evt_button(@ok_button){|event| on_ok_button_clicked(event)}
          evt_button(@cancel_button){|event| on_cancel_button_clicked(event)}
        end
        
        def on_cancel_button_clicked(event)
          end_modal(ID_CANCEL)
        end
        
        def on_ok_button_clicked(event)
          return unless everything_valid?
          
          @map = Map.new(
            @map_id_txt.value.to_i, 
            @map_name_txt.value, 
            Mapset.load(@mapset_drop.string_selection), 
            @width_spin.value, 
            @height_spin.value, 
            @depth_spin.value, 
            @parent_id_txt.value.to_i
          )
          end_modal(ID_OK)
        end
        
        def everything_valid?
          id = @map_id_txt.value.to_i
          parent_id = @parent_id_txt.value.to_i
          
          unless @map_id_txt.value =~ /^\d+$/
            md = MessageDialog.new(self, caption: t.errors.invalid_id.title, message: t.errors.invalid_id.message, style: OK | ICON_WARNING)
            md.show_modal
            return false
          end
          
          unless @parent_id_txt.value =~ /^\d+$/
            md = MessageDialog.new(self, caption: t.errors.invalid_id.title, message: t.errors.invalid_id.message, style: OK | ICON_WARNING)
            md.show_modal
            return false
          end
          
          if id.zero?
            md = MessageDialog.new(self, caption: t.errors.zero_reserved.title, message: t.errors.zero_reserved.message, style: OK | ICON_WARNING)
            md.show_modal
            return false
          end
          
          if Map.id_in_use?(id)
            md = MessageDialog.new(self, caption: t.errors.id_in_use.title, message: t.errors.id_in_use.message % id, style: OK | ICON_WARNING)
            md.show_modal
            return false
          end
          
          if parent_id.nonzero? and !Map.id_in_use?(parent_id)
            md = MessageDialog.new(self, caption: t.errors.id_not_in_use.title, message: t.errors.id_not_in_use.message % parent_id, style: OK | ICON_WARNING)
            md.show_modal
            return false
          end
          
          true
        end
        
      end #NewMapDialog
      
      class EditMapDialog < NewMapDialog
        
        def initialize(parent, mapsets, map)
          hsh = {
            :id => map.id, 
            :name => map.name, 
            :mapsets => mapsets, 
            :width => map.width, 
            :height => map.height, 
            :depth => map.depth, 
            :parent_id => map.parent
          }
          super(parent, hsh)
          self.title = t.dialogs.map_dialog.title_edit
          @map_id_txt.disable #The ID of an already created map can't be changed
        end
        
      end #EditMapDialog
      
    end #Windows
    
  end #GUI
  
end #OpenRubyRMK