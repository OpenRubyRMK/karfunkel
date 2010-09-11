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
      
      #This is the main window. 
      class MainFrame < Wx::Frame
        include Wx
        include R18n::Helpers
        
        #Every control that is not covered by a default wxRuby ID, 
        #is associated with a free one. 
        IDS = {
          :mapset_window => ID_GENERATOR.next, 
          :properties_window => ID_GENERATOR.next, 
          :console => ID_GENERATOR.next
        }.freeze
        
        #Creates the mainwindow. +parent+ should be +nil+. 
        def initialize(parent = nil)
          style = DEFAULT_FRAME_STYLE
          style |= MAXIMIZE if OpenRubyRMK.config["maximize"]
          pos = OpenRubyRMK.config["startup_pos"] == "auto" ? DEFAULT_POSITION : Point.new(*OpenRubyRMK.config["startup_pos"])
          super(parent, title: "#{t.general.application_name} - #{t.general.application_slogan}", pos: pos, size: Size.new(*OpenRubyRMK.config["startup_size"]), style: style)
          self.background_colour = NULL_COLOUR #Ensure that we get a platform-native background color
          self.icon = Icon.new(DATA_DIR.join("ruby16x16.png").to_s, BITMAP_TYPE_PNG)
          #The MAXIMIZE flag only works on windows, so we need to maximize 
          #the window after a short waiting delay on other platforms. 
          Timer.after(1000){self.maximize(true)} if OpenRubyRMK.config["maximize"] and RUBY_PLATFORM !~ /mingw|mswin/
          
          create_menubar
          create_toolbar
          create_statusbar
          create_controls
          create_extra_windows
          setup_event_handlers
          
          $log.info "Running plugins for :mainwindow."
          Plugins[:mainwindow].each{|block| instance_eval(&block)}
        end
        
        private
        
        #==================================
        #GUI setup
        #==================================
        
        def create_menubar
          @menu_bar = MenuBar.new
          @menus = {}
          
          #File
          @menus[:file] = Menu.new
          @menus[:file].append(ID_NEW, t.menus.mainwindow.file.new.name, t.menus.mainwindow.file.new.statusbar)
          @menus[:file].append(ID_OPEN, t.menus.mainwindow.file.open.name, t.menus.mainwindow.file.open.statusbar)
          @menus[:file].append(ID_SAVE, t.menus.mainwindow.file.save.name, t.menus.mainwindow.file.save.statusbar)
          @menus[:file].append(ID_SAVEAS, t.menus.mainwindow.file.saveas.name, t.menus.mainwindow.file.saveas.statusbar)
          @menus[:file].append_separator
          @menus[:file].append(ID_EXIT, t.menus.mainwindow.file.exit.name, t.menus.mainwindow.file.exit.statusbar)
          @menu_bar.append(@menus[:file], t.menus.mainwindow.file.name)
          
          #Edit
          @menus[:edit] = Menu.new
          @menus[:edit].append(ID_ADD, t.menus.mainwindow.edit.new_map.name, t.menus.mainwindow.edit.new_map.statusbar)
          @menu_bar.append(@menus[:edit], t.menus.mainwindow.edit.name)
          
          #View
          @menus[:view] = {}
          @menus[:view][:menu] = Menu.new
          @menus[:view][:windows] = Menu.new
          @menus[:view][:windows].append(IDS[:mapset_window], t.menus.mainwindow.view.windows.mapset.name, t.menus.mainwindow.view.windows.mapset.statusbar)
          @menus[:view][:windows].append(IDS[:properties_window], t.menus.mainwindow.view.windows.properties.name, t.menus.mainwindow.view.windows.properties.statusbar)
          @menus[:view][:menu].append_menu(ID_ANY, t.menus.mainwindow.view.windows.name, @menus[:view][:windows])
          @menu_bar.append(@menus[:view][:menu], t.menus.mainwindow.view.name)
          
          #Extras
          @menus[:extras] = Menu.new
          @menus[:extras].append(IDS[:console], t.menus.mainwindow.extras.console.name, t.menus.mainwindow.extras.console.statusbar)
          @menu_bar.append(@menus[:extras], t.menus.mainwindow.extras.name)
          
          #Help
          @menus[:help] = Menu.new
          @menus[:help].append(ID_HELP, t.menus.mainwindow.help.help.name, t.menus.mainwindow.help.help.statusbar)
          @menus[:help].append_separator
          @menus[:help].append(ID_ABOUT, t.menus.mainwindow.help.about.name, t.menus.mainwindow.help.about.statusbar)
          @menu_bar.append(@menus[:help], t.menus.mainwindow.help.name)
          
          self.menu_bar = @menu_bar
        end
        
        def create_toolbar
          @tool_bar = create_tool_bar
          @tool_bar.add_tool(
            ID_NEW, 
            t.menus.mainwindow.file.new.name, 
            Bitmap.new(DATA_DIR.join("new16x16.png").to_s, BITMAP_TYPE_PNG), 
            NULL_BITMAP, 
            ITEM_NORMAL, 
            t.menus.mainwindow.file.new.tooltip, 
            t.menus.mainwindow.file.new.statusbar
          )
          @tool_bar.add_tool(
            ID_OPEN, 
            t.menus.mainwindow.file.open.name, 
            Bitmap.new(DATA_DIR.join("open16x16.png").to_s, BITMAP_TYPE_PNG), 
            NULL_BITMAP, 
            ITEM_NORMAL, 
            t.menus.mainwindow.file.open.tooltip, 
            t.menus.mainwindow.file.open.statusbar
          )
          
          @tool_bar.realize
        end
        
        def create_statusbar
          @status_bar = create_status_bar(4)
          @status_bar.set_status_widths([-1, -2, -2, -3]) #Contrary to what the docs say, this method takes only one argument (the 2nd from the doc). 
          self.status_bar_pane = 3 #Help strings get displayed here (0-based index)
        end
        
        def create_controls
         @top_splitter = SplitterWindow.new(self, style: SP_3D | SP_LIVE_UPDATE)
          
          #Left side
          @left_panel = Panel.new(@top_splitter)
          
          #Right side
          @right_panel = Panel.new(@top_splitter)
          @right_panel.background_colour = Colour.new(100, 100, 100)
          
          #Put the two sides together
          @top_splitter.minimum_pane_size = 100
          @top_splitter.split_vertically(@left_panel, @right_panel, 300)
          
          #-----------------------------------------------------------
          #Create the left side
          left_sizer = VBoxSizer.new
          @left_panel.sizer = left_sizer
          
          @map_hierarchy = Controls::MapHierarchy.new(@left_panel, "N/A")
          left_sizer.add_item(@map_hierarchy, proportion: 3, flag: EXPAND)
          
          @map_properties = TextCtrl.new(@left_panel, style: TE_MULTILINE, value: "At some time, the selected map's properties will apear here.")
          left_sizer.add_item(@map_properties, proportion: 1, flag: EXPAND)
          
          #-----------------------------------------------------------
          #Create the right side
          
          #NOTE: This is experimental and does nothing senseful. 
          #After the Map save format has been defined, a grid 
          #showing the map will be put here. 
          #~ @dummy_ctrl = StaticText.new(@right_panel, label: "")
          right_sizer = VBoxSizer.new
          @right_panel.sizer = right_sizer
          
          @map_grid = Controls::MapGrid.new(@right_panel)
          right_sizer.add_item(@map_grid, proportion: 1, flag: EXPAND)
        end
        
        def create_extra_windows
          @mapset_window = Windows::MapsetWindow.new(self)
          @properties_window = Windows::PropertiesWindow.new(self)
          @properties_window.on_change{@map_hierarchy.update_map_names}
        end
        
        def setup_event_handlers
          #Menu events
          [:new, :open, :save, :saveas, :exit, #File
          :add, #Edit
          :mapset_window, :properties_window, #View->Windows
          :console, #Extras
          :help, :about #Help
          ].each do |sym| 
            id = if Wx.const_defined?(:"ID_#{sym.upcase}")
              Wx.const_get(:"ID_#{sym.upcase}")
            else
              IDS[sym]
            end
            evt_menu(id){|event| send(:"on_menu_#{sym}", event)}
          end
          
          #Other events
          evt_tree_sel_changed(@map_hierarchy){|event| on_map_hier_clicked(event)}
        end
        
        #==================================
        #Event handlers
        #==================================
        
        def on_menu_new(event)
          
        end
        
        def on_menu_open(event)
          fd = FileDialog.new(self, 
            message: t.dialogs.open_project.title, 
            default_dir: THE_APP.remembered_dir.to_s, 
            wildcard: "OpenRubyRMK project files (*.rmk)|*.rmk;*.RMK", 
            style: FD_OPEN | FD_FILE_MUST_EXIST
          )
          return if fd.show_modal == ID_CANCEL
          #Remember the directory for convenience
          THE_APP.remembered_dir = Pathname.new(fd.directory)
          #Set the OpenRubyRMK project dir, from which all other dirs can be computed
          OpenRubyRMK.project_path = Pathname.new(fd.directory).parent
          #Clear the temporary directory for new files
          OpenRubyRMK.clear_tempdir
          #Extract the projects mapsets and characters (into the temporary directory)
          Mapset.extract_archives
          Character.extract_archives
          
          structure_hsh = OpenRubyRMK.project_maps_structure_file.open("rb"){|f| Marshal.load(f)}
          @maps = buildup_hash(structure_hsh)
          @project_name = fd.filename.match(/\.rmk$/).pre_match
          @map_hierarchy.recreate_tree!(@project_name, @maps)
        end
        
        def on_menu_save(event)
          return show_no_project_dlg unless OpenRubyRMK.has_project?
          
          
        end
        
        def on_menu_saveas(event)
          return show_no_project_dlg unless OpenRubyRMK.has_project?
          
          
        end
        
        def on_menu_exit(event)
          close
        end
        
        def on_menu_mapset_window(event)
          return show_no_project_dlg unless OpenRubyRMK.has_project?
          return if @mapset_window.shown?
          
          @mapset_window.show
        end
        
        def on_menu_properties_window(event)
          return show_no_project_dlg unless OpenRubyRMK.has_project?
          return if @properties_window.shown?
          
          @properties_window.show
        end
        
        def on_menu_add(event)
          return show_no_project_dlg unless OpenRubyRMK.has_project?
          
          md = Windows::MapDialog.new(self, available_mapsets: [Mapset.load("test1.png")]) #DEBUG: Mapsets?
          return if md.show_modal == ID_CANCEL
          
          add_map_to_hierarchy_control(md.map)
        end
        
        def on_menu_console(event)
          cons = Windows::ConsoleWindow.new(self)
          cons.show
        end
        
        def on_menu_help(event)
          field = MapField.new(@map_hierarchy.selected_map, 0, 0, 0, 1, 0)
          @map_grid.table.set_value(0, 0, field)
          @map_grid.refresh
        end
        
        def on_menu_about(event)
          i = AboutDialogInfo.new
          i.artists = ["Tango project ( http://tango.freedesktop.org )", "Yukihiro Matsumoto ( http://www.rubyidentity.org )"]
          i.developers = ["The OpenRubyRMK Team <openrubyrmk@googlemail.com>"]
          i.translators = t.general.translators.split(/,\s?/)
          #i.doc_writers = []
          i.copyright = "Copyright © 2010 OpenRubyRMK Team"
          i.name = t.general.application_name
          i.version = OpenRubyRMK::VERSION
          i.description = t.general.description
          i.icon = Icon.new(DATA_DIR.join("ruby32x32.png").to_s, BITMAP_TYPE_PNG)
          i.license = ROOT_DIR.join("COPYING.txt").read
          i.web_site = "http://wiki.ruby-portal.de/OpenRubyRMK"
          Wx.about_box(i)
        end
        
        def on_map_hier_clicked(event)
          if event.item.nonzero?
            #~ @dummy_ctrl.label = @map_hierarchy.get_item_data(event.item).inspect
            if @map_hierarchy.selected_map.nil?
              @map_grid.disable
            else
              @map_grid.enable
              @map_grid.table = Controls::MapGrid::MapTableBase.new(@map_hierarchy.selected_map)
            end
            @map_grid.refresh #The grid doesn't get updated otherwise
            @mapset_window.reload(@map_hierarchy.selected_map.nil? ? nil : @map_hierarchy.selected_map.mapset)
            @properties_window.reload(@map_hierarchy.selected_map, [Mapset.load("test1.png")]) #DEBUG Mapsets?
          end
          event.skip
        end
        
        #==================================
        #Helper methods
        #==================================
        
        #{map => MAP, children => {}}
        def buildup_hash(hsh)
          result = {}
          hsh.each_pair do |map_id, children_hsh|
            result[map_id] = {}
            result[map_id][:map] = Map.load(map_id)
            result[map_id][:children] = buildup_hash(children_hsh)
          end
          result
        end
        
        def add_map_to_hierarchy_control(map)
          if map.parent == 0 #0 means no parent
            @maps[map.id] = md.map #TODO - what's the sense of this? It's done by parents.empty? below
          else
            parents = map.parent_ids
            if parents.empty? #We want to add to root and root doesn't have a :children key, just plain IDs
              @maps[map.id] = {:map => map, :children => {}}
            else #We have at least one parent
              last_parent_hsh = @maps
              until parents.empty?
                if last_parent_hsh.has_key?(:children) #Child
                  last_parent_hsh = last_parent_hsh[:children][parents.shift] #We get a reference to a part of the original hash here
                else #Root element
                  last_parent_hsh = last_parent_hsh[parents.shift] #We get a reference to a part of the original hash here
                end
              end
              
              #Add the map to the end of the hierarchy
              last_parent_hsh[:children][map.id] = {:map => map, :children => {}}
            end
          end
          @map_hierarchy.recreate_tree!(@project_name, @maps)
        end
        
        def show_no_project_dlg
          md = MessageDialog.new(self, caption: t.errors.no_project.title, message: t.errors.no_project.message, style: OK | ICON_WARNING)
          md.show_modal
        end
        
      end #MainFrame
      
    end #Windows
    
  end #GUI
  
end #OpenRubyRMK