# -*- coding: utf-8 -*-
# Dealing with tilesets.

module OpenRubyRMK::Karfunkel::Plugin::Base

  process_request :new_tileset do
    # Make all names obey the same format. No spaces, lowercase.
    name = request["name"].gsub(" ", "_").downcase
    name << ".png" unless name.end_with?(".png")
    path = @selected_project.paths.tilesets_dir + name
    answer! :reject, :reason => :exists if path.file?

    pic = Base64.decode64(request["picture"])
    answer! :reject, :reason => :bad_format unless pic.bytes.first(4).drop(1).map(&:chr).join == "PNG"

    File.open(@selected_project.paths.tilesets_dir + name, "wb"){|file| file.write(pic)}
    broadcast :tileset_added, :name => name
    answer :ok
  end

  process_request :delete_tileset do |c, r|
    path = @selected_project.paths.tilesets_dir + request["name"]
    answer! :reject, :reason => :not_found unless path.file?

    path.delete
    broadcast :tileset_deleted, :name => request["name"]
    answer :ok
  end

end
