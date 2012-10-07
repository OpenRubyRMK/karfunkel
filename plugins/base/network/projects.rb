# -*- coding: utf-8 -*-
# Project management requests.

module OpenRubyRMK::Karfunkel::Plugin::Base

  process_request :load_project do
    answer! :rejected, :reason => :not_found unless File.directory?(request[:path])

    # FIXME: Use EventMachine.defer + :processing answer as this operation may last long!
    @projects << OpenRubyRMK::Karfunkel::Plugin::Base::Project.load(request[:path])
    @selected_project = @projects.last
    answer :ok, :id => @selected_project.id
    broadcast :project_selected, :id => @selected_project.id
  end

  process_request :new_project do
    answer! :rejected, :reason => :already_exists if File.exists?(request[:path])

    @projects << OpenRubyRMK::Karfunkel::Plugin::Base::Project.new(request[:path])
    @selected_project = @projects.last
    answer :ok, :id => @selected_project.id
    broadcast :project_selected, :id => @selected_project.id
  end

  process_request :close_project do
    proj = @projects.find{|p| p.id == request[:id].to_i}
    answer! :reject, :reason => :not_found unless proj

    proj.save
    @selected_project = nil if @selected_project == proj
    @projects.delete(proj)
    answer :ok

    # If the active project was closed, notify the clients.
    broadcast :project_selected, :id => -1 unless @selected_project
  end

  process_request :delete_project do
    proj = @projects.find{|p| p.id == request[:id].to_i}
    answer! :reject, :not_found unless proj

    @selected_project = nil if @selected_project == proj
    @projects.delete(proj)
    proj.delete!
    answer :ok

    # If the active project was deleted, notify the clients.
    broadcast :project_selected, :id => -1 unless @selected_project
  end

  process_request :save_project do
    @selected_project.save
    answer :ok
  end

end
