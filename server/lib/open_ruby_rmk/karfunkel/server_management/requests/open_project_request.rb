#Encoding: UTF-8

OpenRubyRMK::Karfunkel::SM::Request.define :OpenProject do
  
  attribute :file
  
  def execute
    answer :ok, :foo => "Foo Bar Baz"
  end
  
end