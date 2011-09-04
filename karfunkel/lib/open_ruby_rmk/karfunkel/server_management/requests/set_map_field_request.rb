#Encoding: UTF-8

OpenRubyRMK::Karfunkel::SM::Request.define :SetMapField do
  
  parameter :foo
  
  def execute(pars)
    map = Karfunkel.selected_project["mapname"]
    map[1, 2, 3] = [4, 9]
  end
  
end
