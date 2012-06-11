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
    require_relative "base/project"
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

  process_request :hello do |c, r|
    answer :rejected, :reason => :already_authenticated and break if c.authenticated?
    log.debug "Trying to authenticate '#{c}'..."

    #TODO: Here one could add password checks and other nice things
    c.id            = kf.generate_client_id
    c.authenticated = true
    
    log.info "[#{c}] Authenticated."
    
    answer c, r, :ok, :my_version => OpenRubyRMK::Karfunkel::VERSION,
                 :my_project      => kf.selected_project.to_s,
                 :my_clients_num  => kf.clients.count,
                 :your_id         => c.id
  end

  process_request :ping do |c, r|
    #If Karfunkel gets a PING request, we just answer it as OK and
    #are done with it.
    answer c, r, :ok
  end

  process_response :ping do |c, r|
    #Nothing is necessary here, because a client’s availability status
    #is set automatically if it sends a reponse. I just place the
    #method here, because without it we would get a NotImplementedError
    #exception.
  end

  process_request :shutdown do |c, r|
    # Trying to stop the server will issue requests
    # to all connected clients asking them to agree
    answer c, r, :processing
    OpenRubyRMK::Karfunkel.instance.stop(c)
  end

  # If we get this, a SHUTDOWN request has been answered.
  process_response :shutdown do |c, r|
    c.accepted_shutdown = r.status == "ok" ? true : false
    # If all clients have accepted, stop the server
    OpenRubyRMK::Karfunkel.instance.stop! if OpenRubyRMK::Karfunkel.instance.clients.all?(&:accepted_shutdown)
  end

  ########################################
  # Project management

  process_request :load_project do |c, r|
    answer(c, r, :rejected, :reason => :not_found) and break unless File.directory?(r[:path])

    @projects << OpenRubyRMK::Karfunkel::Plugin::Base::Project.load(r[:path])
    answer c, r, :ok, :id => @projects.last.id
  end

  process_request :new_project do |c, r|
    answer(c, r, :rejected, :reason => :already_exists) and break if File.exists?(r[:path])

    @projects << OpenRubyRMK::Karfunkel::Plugin::Base::Project.new(r[:path])
    answer c, r, :ok, :id => @project.id
  end

  process_request :close_project do |c, r|
    proj = @projects.find{|p| p.id == r[:id].to_i}
    answer c, r, :reject, :reason => :not_found and break unless proj

    @selected_project.save
    @selected_project = nil if @selected_project == proj
    @projects.delete(proj)
    answer :ok
  end

  process_request :delete_project do |c, r|
    proj = @projects.find{|p| p.id == r[:id].to_i}
    answer c, r, :reject, :not_found and break unless proj

    @selected_project = nil if @selected_project == proj
    @projects.delete(proj)
    proj.delete!
    answer c, r, :ok
  end

  process_request :save_project do |c, r|
    @selected_project.save
    answer c, r, :ok
  end

  ########################################
  # Tileset stuff

  process_request :new_tileset do |c, r|
    answer c, r, :reject, :reason => :missing_parameter, :name => "picture"  and return unless r["picture"]
    answer c, r, :reject, :reason => :missing_parameter, :name, => "name"    and return unless r["name"]

    # Make all names obey the same format. No spaces, lowercase.
    name = r["name"].gsub(" ", "_").downcase
    name << ".png" unless name.end_with?(".png")
    path = @selected_project.paths.tilesets_dir + name
    answer c, r, :reject, :reason => :exists and return if path.file?

    pic = Base64.decode64(r["picture"])
    answer c, r, :reject, :reason => :bad_format and return unless pic.bytes.first(4).drop(1).map(&:chr).join == "PNG"

    File.open(@selected_project.paths.tilesets_dir + name, "wb"){|file| file.write(pic)}
    broadcast :tileset_added, :name => name
    answer c, r, :ok
  end

  process_request :delete_tileset do |c, r|
    answer c, r, :reject, :reason => :missing_parameter and return unless r["name"]

    path = @selected_project.paths.tilesets_dir + name
    answer c, r, :reject, :reason => :not_found and return unless path.file?

    path.delete
    broadcast :tileset_deleted, :name => r["name"]
    answer c, r, :ok
  end

  ########################################
  # Map management

  process_request :new_map do |c, r|
    map = Base::Map.new(@selected_project, r["name"]) # If no name is given, nil passed -> default value -> auto-generated name
    broadcast :map_added, :id => map.id, :name => map.name
    answer c, r, :ok, :id => map.id
  end

  process_request :delete_map do |c, r|
    id = Integer(r["id"]) # Raises if id is not given

    parent_map = catch(:found) do
      @selected_project.root_maps.each do |root_map|
        root_map.traverse(true) do |map|
          throw :found, map if map.has_child?(id)
        end
      end
      answer c, r, :reject, :reason => :not_found and return
    end

    parent_map.delete(id)
    broadcast :map_deleted, :id => id
    answer c, r, :ok
  end

end
