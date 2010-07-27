#!/usr/bin/env ruby
#Encoding: UTF-8

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
        menu.append(ID_NEW, t.menus.file.new.name, t.menus.file.new.tooltip)
        menu.append(ID_OPEN, t.menus.file.open.name, t.menus.file.open.tooltip)
        menu.append(ID_SAVE, t.menus.file.save.name, t.menus.file.save.tooltip)
        menu.append(ID_SAVEAS, t.menus.file.saveas.name, t.menus.file.saveas.tooltip)
        menu.append_separator
        menu.append(ID_EXIT, t.menus.file.exit.name, t.menus.file.exit.tooltip)
        @menu_bar.append(menu, t.menus.file.name)
        
        #Edit
        menu = Menu.new
        @menu_bar.append(menu, t.menus.edit.name)
        
        #Help
        menu = Menu.new
        menu.append(ID_HELP, t.menus.help.help.name, t.menus.help.help.tooltip)
        menu.append_separator
        menu.append(ID_ABOUT, t.menus.help.about.name, t.menus.help.about.tooltip)
        @menu_bar.append(menu, t.menus.help.name)
        
        #TODO - at this point, load external menu plugins. 
        
        self.menu_bar = @menu_bar
      end
      
      def create_toolbar
        @tool_bar = create_tool_bar
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
        #~ @map_hierarchy = TextCtrl.new(@left_panel, style: TE_MULTILINE)
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
        #Edit
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
        #NOTE: This is experimental and only used for the time we don't 
        #have specified how we want to save data. 
        #So I just construct something here, rather than accessing something saved. 
        @maps = {
          "Map1" => "Here's a great Map object -- we just don't have a Map class!", 
          "Map2" => "2", 
          "Map3" => {:map => "3", :hsh => {
            "Map3-1" => "3-1", 
            "Map3-2" => {:map => "3-2", :hsh => {
              "Map3-2-1" => "3-2-1"
            }}, 
            "Map3-3" => "3-3"
          }}
        }
        @map_hierarchy.recreate_tree!("MyProject", @maps)
      end
      
      def on_menu_save(event)
        
      end
      
      def on_menu_saveas(event)
        
      end
      
      def on_menu_exit(event)
        close
      end
      
      def on_menu_help(event)
        
      end
      
      def on_menu_about(event)
        i = AboutDialogInfo.new
        i.artists = ["Abdylas Tynyshov", "Yukihiro Matsumoto"]
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
          @dummy_ctrl.label = @map_hierarchy.get_item_data(event.item).to_s
        end
        event.skip
      end
      
    end
    
  end
  
end