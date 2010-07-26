#!/usr/bin/env ruby
#Encoding: UTF-8

module OpenRubyRMK
  
  module GUI
    
    class MainFrame < Wx::Frame
      include Wx
      include R18n::Helpers
      
      def initialize(parent = nil)
        super(parent, title: "OpenRubyRMK - The free and OpenSource RPG creation program!", size: Size.new(600, 400), style: DEFAULT_FRAME_STYLE | MAXIMIZE)
        self.background_colour = NULL_COLOUR #Ensure that we get a platform-native background color
        #The MAXIMIZE flag only works on windows, so we need to maximize 
        #the window after a short waiting delay on other platforms. 
        Timer.after(1000){self.maximize(true)} unless RUBY_PLATFORM =~ /mingw|mswin/
        
        create_menu
        create_statusbar
      end
      
      private
      
      def create_menu
        menu_bar = MenuBar.new
        
        #File
        menu = Menu.new
        menu.append(ID_OPEN, t.menus.file.open.name, t.menus.file.open.tooltip)
        menu.append(ID_SAVE, t.menus.file.save.name, t.menus.file.save.tooltip)
        menu.append(ID_SAVEAS, t.menus.file.saveas.name, t.menus.file.saveas.tooltip)
        menu.append_separator
        menu.append(ID_EXIT, t.menus.file.exit.name, t.menus.file.exit.tooltip)
        menu_bar.append(menu, t.menus.file.name)
        
        #Edit
        menu = Menu.new
        menu_bar.append(menu, t.menus.edit.name)
        
        #Help
        menu = Menu.new
        menu.append(ID_HELP, t.menus.help.help.name, t.menus.help.help.tooltip)
        menu.append_separator
        menu.append(ID_ABOUT, t.menus.help.about.name, t.menus.help.about.tooltip)
        menu_bar.append(menu, t.menus.help.name)
        
        self.menu_bar = menu_bar
      end
      
      def create_statusbar
        status_bar = StatusBar.new(self)
        status_bar.set_fields_count(4)
        status_bar.set_status_widths([-1, -2, -2, -3]) #Contrary to what the docs say, this method takes only one argument (the 2nd from the doc). 
        self.status_bar = status_bar
        self.status_bar_pane = 3 #Help strings get displayed here (0-based index)
      end
      
    end
    
  end
  
end