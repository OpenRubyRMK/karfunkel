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
    
    class MainFrame < Wx::Frame
      include Wx
      include R18n::Helpers
      
      def initialize(parent = nil)
        super(parent, title: "#{t.general.application_name} - #{t.general.application_slogan}", size: Size.new(600, 400), style: DEFAULT_FRAME_STYLE | MAXIMIZE)
        self.background_colour = NULL_COLOUR #Ensure that we get a platform-native background color
        self.icon = Icon.new(DATA_DIR.join("ruby16x16.png").to_s, BITMAP_TYPE_PNG)
        #The MAXIMIZE flag only works on windows, so we need to maximize 
        #the window after a short waiting delay on other platforms. 
        Timer.after(1000){self.maximize(true)} unless RUBY_PLATFORM =~ /mingw|mswin/
        
        #This will contain the path of the project we're currently working with. 
        @project_path = nil
        
        create_menubar
        create_toolbar
        create_statusbar
        create_controls
        setup_event_handlers
      end
      
      private
      
      #==================================
      #GUI setup
      #==================================
      
      def create_menubar
        @menu_bar = MenuBar.new
        
        #File
        menu = Menu.new
        menu.append(ID_NEW, t.menus.file.new.name, t.menus.file.new.statusbar)
        menu.append(ID_OPEN, t.menus.file.open.name, t.menus.file.open.statusbar)
        menu.append(ID_SAVE, t.menus.file.save.name, t.menus.file.save.statusbar)
        menu.append(ID_SAVEAS, t.menus.file.saveas.name, t.menus.file.saveas.statusbar)
        menu.append_separator
        menu.append(ID_EXIT, t.menus.file.exit.name, t.menus.file.exit.statusbar)
        @menu_bar.append(menu, t.menus.file.name)
        
        #Edit
        menu = Menu.new
        @menu_bar.append(menu, t.menus.edit.name)
        menu.append(ID_ADD, t.menus.edit.new_map.name, t.menus.edit.new_map.statusbar)
        
        #Help
        menu = Menu.new
        menu.append(ID_HELP, t.menus.help.help.name, t.menus.help.help.statusbar)
        menu.append_separator
        menu.append(ID_ABOUT, t.menus.help.about.name, t.menus.help.about.statusbar)
        @menu_bar.append(menu, t.menus.help.name)
        
        #TODO - at this point, load external menu plugins. 
        
        self.menu_bar = @menu_bar
      end
      
      def create_toolbar
        @tool_bar = create_tool_bar
        @tool_bar.add_tool(
          ID_NEW, 
          t.menus.file.new.name, 
          Bitmap.new(DATA_DIR.join("new16x16.png").to_s, BITMAP_TYPE_PNG), 
          NULL_BITMAP, 
          ITEM_NORMAL, 
          t.menus.file.new.tooltip, 
          t.menus.file.new.statusbar
        )
        @tool_bar.add_tool(
          ID_OPEN, 
          t.menus.file.open.name, 
          Bitmap.new(DATA_DIR.join("open16x16.png").to_s, BITMAP_TYPE_PNG), 
          NULL_BITMAP, 
          ITEM_NORMAL, 
          t.menus.file.open.tooltip, 
          t.menus.file.open.statusbar
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
        
        @map_hierarchy = MapHierarchy.new(@left_panel, "N/A")
        left_sizer.add_item(@map_hierarchy, proportion: 3, flag: EXPAND)
        
        @map_properties = TextCtrl.new(@left_panel, style: TE_MULTILINE, value: "At some time, the selected map's properties will apear here.")
        left_sizer.add_item(@map_properties, proportion: 1, flag: EXPAND)
        
        #-----------------------------------------------------------
        #Create the right side
        
        #NOTE: This is experimental and does nothing senseful. 
        #After the Map save format has been defined, a grid 
        #showing the map will be put here. 
        @dummy_ctrl = StaticText.new(@right_panel, label: "")
      end
      
      def setup_event_handlers
        [:new, :open, :save, :saveas, :exit, #File
        :add, #Edit
        :help, :about #Help
        ].each{|sym| evt_menu(Wx.const_get(:"ID_#{sym.upcase}")){|event| send(:"on_menu_#{sym}", event)}}
        
        evt_tree_sel_changed(@map_hierarchy){|event| on_map_hier_clicked(event)}
        
        #TODO - at this point, load external event handler plugins. 
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
      
      def on_menu_add(event)
        return show_no_project_dlg unless OpenRubyRMK.has_project?
        
        md = NewMapDialog.new(self, available_mapsets: [Mapset.load("test")]) #DEBUG: Mapsets?
        return if md.show_modal == ID_CANCEL
        
        #Put the new map in the right place inside the map hierarchy
        if md.map.parent == 0 #0 means no parent
          @maps[md.map.id] = md.map
        else
          parents = md.map.parent_ids
          if parents.empty? #We want to add to root and root doesn't have a :children key, just plain IDs
            @maps[md.map.id] = {:map => md.map, :children => {}}
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
            last_parent_hsh[:children][md.map.id] = {:map => md.map, :children => {}}
          end
        end
        @map_hierarchy.recreate_tree!(@project_name, @maps)
      end
      
      def on_menu_help(event)
        
      end
      
      def on_menu_about(event)
        i = AboutDialogInfo.new
        i.artists = ["Tango project ( http://tango.freedesktop.org )", "Yukihiro Matsumoto ( http://www.rubyidentity.org )"]
        i.developers = %w[Hanmac Kjarrigan Quintus]
        i.translators = t.general.translators.split(/,\s?/)
        #i.doc_writers = []
        i.copyright = "Copyright © 2010 Hanmac, Kjarrigan, Quintus"
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
          @dummy_ctrl.label = @map_hierarchy.get_item_data(event.item).inspect
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
      
      def show_no_project_dlg
        md = MessageDialog.new(self, caption: t.errors.no_project.title, message: t.errors.no_project.message, style: OK | ICON_WARNING)
        md.show_modal
      end
      
    end
    
  end
  
end