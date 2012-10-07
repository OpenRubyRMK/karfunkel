# -*- coding: utf-8 -*-
# Map management

module OpenRubyRMK::Karfunkel::Plugin::Base

  process_request :new_map do
    #NOTE: "new map" doesn’t necessarily mean "new root map"!

    map = Base::Map.new(@selected_project, request["name"]) # If no name is given, nil passed -> default value -> auto-generated name
    broadcast :map_added, :id => map.id, :name => map.name
    answer :ok, :id => map.id
  end

  process_request :delete_map do
    id = request["id"].to_i

    parent_map = catch(:found) do
      @selected_project.root_maps.each do |root_map|
        root_map.traverse(true) do |map|
          throw :found, map if map.has_child?(id)
        end
      end
      answer! :reject, :reason => :not_found
    end

    parent_map.delete(id)
    broadcast :map_deleted, :id => id
    answer :ok
  end

end
