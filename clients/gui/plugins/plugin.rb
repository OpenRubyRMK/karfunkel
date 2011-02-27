#Encoding: UTF-8
#This is a sample plugin that adds a new menu "testmenu" to 
#OpenRubyRMK's main window. 

=begin
plug_into :mainwindow do
  menu = Menu.new
  id = THE_APP.id_generator.next
  menu.append(id, "test")
  @menu_bar.append(menu, "testmenu")
  
  evt_menu(id){|event| puts "test"}
end
=end