# -*- coding: utf-8 --
# Category handling

module OpenRubyRMK::Karfunkel::Plugin::Base

  process_request :new_category do
    cat = OpenRubyRMK::Karfunkel::Plugin::Base::Category.new(request["name"].downcase)
    @selected_project.add_category(cat)
    broadcast :category_added, :name => cat.name
    answer :ok, :name => cat.name
  end

  process_request :delete_category do
    @selected_project.delete_category(request["name"])
    broadcast :category_deleted, :name => request["name"]
    answer :ok
  end

end
