# -*- coding: utf-8 -*-
# Handling of global scripts.

module OpenRubyRMK::Karfunkel::Plugin::Base

  process_request :new_global_script do
    name = request["name"].gsub(" ", "_").downcase
    name << ".rb" unless name.end_with?(".rb")
    path = @selected_project.paths.script_dir + name
    answer! :reject, :reason => :exists if path.file?

    File.open(path, "w"){|f| f.write(request["code"].force_encoding("UTF-8"))}
    answer :ok
    broadcast :global_script_added, :name => name
  end

  process_request :delete_global_script do
    path = @selected_project.paths.script_dir + request["name"].gsub(" ", "_").downcase
    answer! :reject, :reason => :not_found unless path.file?

    path.delete
    answer :ok
    broadcast :global_script_deleted, :name => request["name"]
  end

end
