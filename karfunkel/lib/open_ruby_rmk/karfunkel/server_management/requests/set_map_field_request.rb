#Encoding: UTF-8

OpenRubyRMK::Karfunkel::SM::Request.define :SetMapField do
  
  attribute :foo
  
  execute do |client|
    map = Karfunkel.selected_project["mapname"]
    map[1, 2, 3] = [4, 9]
  end
  
end