# -*- coding: utf-8 -*-
# This file is part of OpenRubyRMK.
# 
# Copyright © 2012 OpenRubyRMK Team
# 
# OpenRubyRMK is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
# 
# OpenRubyRMK is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with OpenRubyRMK.  If not, see <http://www.gnu.org/licenses/>.

#The base plugin providing Karfunkel with the necessary infrastructure
#to act properly. It defines things like how to act upon a +shutdown+
#request and the project management things. Unless you really know
#what you’re doing, you want this plugin to be enabled.
module OpenRubyRMK::Karfunkel::Plugin::Base
  include OpenRubyRMK::Karfunkel::Plugin

  #Load the project management classes when then
  #plugin is activated.
  def self.included(*)
    require "base64"
    require "zlib"
    require "archive/tar/minitar"
    require "tiled_tmx"
    require_relative "base/invalidatable"
    require_relative "base/project"
    require_relative "base/map"
    require_relative "base/category"
  end

  ########################################
  # Server control and authentication

  #All loaded projects as an array.
  attr_reader :projects
  #The currently selected project. +nil+ if no project
  #is selected currently.
  attr_reader :selected_project

  #*Hooked*. Sets up basic project management
  #infrastructure.
  def start
    super
    @projects         = []
    @selected_project = nil
  end

  process_request :hello do
    answer :rejected, :reason => :already_authenticated and break if client.authenticated?
    log.debug "Trying to authenticate '#{client}'..."

    #TODO: Here one could add password checks and other nice things
    client.id            = kf.generate_client_id
    client.authenticated = true
    
    log.info "[#{client}] Authenticated."
    
    answer :ok, :my_version => OpenRubyRMK::Karfunkel::VERSION,
           :my_project      => kf.selected_project.to_s,
           :my_clients_num  => kf.clients.count,
           :your_id         => client.id
  end

  process_request :ping do
    #If Karfunkel gets a PING request, we just answer it as OK and
    #are done with it.
    answer :ok
  end

  process_response :ping do
    #Nothing is necessary here, because a client’s availability status
    #is set automatically if it sends a reponse. I just place the
    #method here, because without it we would get a NotImplementedError
    #exception.
  end

  process_request :shutdown do
    # Trying to stop the server will issue requests
    # to all connected clients asking them to agree
    answer :ok
    OpenRubyRMK::Karfunkel.instance.stop(client)
  end

  # If we get this, a SHUTDOWN request has been answered.
  process_response :shutdown do
    client.accepted_shutdown = request.status == "ok" ? true : false
    log.info("[#{client}] Shutdown accepted")
    # If all clients have accepted, stop the server
    OpenRubyRMK::Karfunkel.instance.stop! if OpenRubyRMK::Karfunkel.instance.clients.all?(&:accepted_shutdown)
  end

  ########################################
  # Project management

  process_request :load_project do
    answer(:rejected, :reason => :not_found) and break unless File.directory?(request[:path])

    # FIXME: Use EventMachine.defer + :processing answer as this operation may last long!
    @projects << OpenRubyRMK::Karfunkel::Plugin::Base::Project.load(request[:path])
    @selected_project = @projects.last
    answer :ok, :id => @selected_project.id
    broadcast :project_selected, :id => @selected_project.id
  end

  process_request :new_project do
    answer(:rejected, :reason => :already_exists) and break if File.exists?(request[:path])

    @projects << OpenRubyRMK::Karfunkel::Plugin::Base::Project.new(request[:path])
    @selected_project = @projects.last
    answer :ok, :id => @selected_project.id
    broadcast :project_selected, :id => @selected_project.id
  end

  process_request :close_project do
    proj = @projects.find{|p| p.id == request[:id].to_i}
    answer :reject, :reason => :not_found and break unless proj

    @selected_project.save
    @selected_project = nil if @selected_project == proj
    @projects.delete(proj)
    answer :ok
    broadcast :project_selected, :id => -1
  end

  process_request :delete_project do
    proj = @projects.find{|p| p.id == request[:id].to_i}
    answer :reject, :not_found and break unless proj

    @selected_project = nil if @selected_project == proj
    @projects.delete(proj)
    proj.delete!
    answer :ok
    broadcast :project_selected, :id => -1
  end

  process_request :save_project do
    @selected_project.save
    answer :ok
  end

  ########################################
  # Global scripts

  process_request :new_global_script do
    name = request["name"].gsub(" ", "_").downcase
    name << ".rb" unless name.end_with?(".rb")
    path = @selected_project.paths.script_dir + name
    answer :reject, :reason => :exists and return if path.file?

    File.open(path, "w"){|f| f.write(request["code"].force_encoding("UTF-8"))}
    answer :ok
    broadcast :global_script_added, :name => name
  end

  process_request :delete_global_script do
    path = @selected_project.paths.script_dir + request["name"]
    answer :reject, :reason => :not_found and return unless path.file?

    path.delete
    answer :ok
    broadcast :global_script_deleted, :name => request["name"]
  end

  ########################################
  # Tileset stuff

  process_request :new_tileset do
    answer :reject, :reason => :missing_parameter, :name => "picture"  and return unless request["picture"]
    answer :reject, :reason => :missing_parameter, :name => "name"     and return unless request["name"]

    # Make all names obey the same format. No spaces, lowercase.
    name = request["name"].gsub(" ", "_").downcase
    name << ".png" unless name.end_with?(".png")
    path = @selected_project.paths.tilesets_dir + name
    answer :reject, :reason => :exists and return if path.file?

    pic = Base64.decode64(request["picture"])
    answer :reject, :reason => :bad_format and return unless pic.bytes.first(4).drop(1).map(&:chr).join == "PNG"

    File.open(@selected_project.paths.tilesets_dir + name, "wb"){|file| file.write(pic)}
    broadcast :tileset_added, :name => name
    answer :ok
  end

  process_request :delete_tileset do |c, r|
    answer :reject, :reason => :missing_parameter and return unless request["name"]

    path = @selected_project.paths.tilesets_dir + name
    answer :reject, :reason => :not_found and return unless path.file?

    path.delete
    broadcast :tileset_deleted, :name => request["name"]
    answer :ok
  end

  ########################################
  # Map management

  process_request :new_map do
    #NOTE: "new map" doesn’t necessarily mean "new root map"!

    map = Base::Map.new(@selected_project, request["name"]) # If no name is given, nil passed -> default value -> auto-generated name
    broadcast :map_added, :id => map.id, :name => map.name
    answer :ok, :id => map.id
  end

  process_request :delete_map do
    id = Integer(request["id"]) # Raises if id is not given

    parent_map = catch(:found) do
      @selected_project.root_maps.each do |root_map|
        root_map.traverse(true) do |map|
          throw :found, map if map.has_child?(id)
        end
      end
      answer :reject, :reason => :not_found and return
    end

    parent_map.delete(id)
    broadcast :map_deleted, :id => id
    answer :ok
  end

  ########################################
  # Categories

  process_request :new_category do
    answer :reject, :reason => :missing_parameter, :name => "name"  and return unless request["name"]
    cat = OpenRubyRMK::Karfunkel::Plugin::Base::Category.new(request["name"])
    @selected_project.add_category(cat)
    broadcast :category_added, :name => cat.name
    answer :ok, :name => cat.name
  end

  process_request :delete_category do
    answer :reject, :reason => :missing_parameter, :name => "name"  and return unless request["name"]
    @selected_project.delete_category(request["name"])
    broadcast :category_deleted, :name => request["name"]
  end

end
