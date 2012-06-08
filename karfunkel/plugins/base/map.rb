# -*- coding: utf-8 -*-

module OpenRubyRMK::Karfunkel::Plugin::Base

  #Class representing a single map inside a project. This class
  #builds upon ruby-tmx’ <tt>TiledTmx::Map</tt> class and extends
  #it with name, ID and parent/child information.
  #
  #Each map may have a arbitrary number of child maps.
  class Map < TiledTmx::Map
    include OpenRubyRMK::Karfunkel::Plugin::Helpers
    extend OpenRubyRMK::Karfunkel::Plugin::Helpers

    #The ID of the map. Unique within a project.
    attr_reader :id

    #The name of the map. Not necessarily unique.
    attr_reader :name

    #An (unsorted) array of child maps of this map.
    attr_reader :children

    #The Project instance this map belongs to.
    attr_reader :project

    #Loads a map from the XML file at the given +path+.
    #This is the same as ruby-tmx’ +load_xml+ method, but
    #includes a log message.
    #==Parameter
    #[path] The location of the XML file to load.
    #==Return value
    #An instance of this class.
    #==Remarks
    #Note this method does not know about map hierarchies,
    #because this isn’t possible with the native TMX format
    #which we don’t want to break. Instead, the map
    #hierarchies are stored in a separate file named *maps.xml*
    #which is loaded by Project::load and inspected for child
    #maps, which then are added to the map loaded by this method
    #by means of #add_child. To conclude, when you load a map
    #with this method, it’s +children+ attribute will be an
    #empty array.
    def self.load(project, name, path)
      logger.debug "Loading map from #{path}"
      obj = load_xml(path)
      obj.instance_eval do
        @project  = project
        @id       = File.basename(path).to_s.to_i # Pathname("foo/0004.tmx") -> Pathname("0004.tmx") -> "0004.tmx" -> 4
        @name     = name
        @children = []
      end

      obj
    end

    #Creates a new instance of this class.
    #==Parameters
    #[name] The name of the map.
    #[*args] Passed on to <tt>TiledTmx::Map.new</tt>.
    #==Return value
    #An instance of this class.
    #==Remarks
    #Note that the unique ID is threadsafely generated
    #automatically <b>from the currently selected
    #project</b>, i.e. OpenRubyRMK::Karfunkel#active_project.
    #If you want to create a map for another project, you
    #have to activate it first.
    def initialize(project, name = nil, *args)
      logger.info "Creating a new map"
      super(*args)
      @project  = project
      @id       = generate_id
      @name     = name || "Map_#@id"
      @children = []
    end

    def eql?(other)
      return false unless other.respond_to?(:project) and other.respond_to?(:id)

      @project == other.project && @id == other.id
    end

    #Human-readable description of form:
    #  #<OpenRubyRMK::Karfunkel::Plugins::Base::Project <mapname> (<id>) with <num> children>
    def inspect
      "#<#{self.class} #@name (#@id) with #{@children.count} children>"
    end

    #Checks whether a map is somewhere an ancestor of
    #another, i.e. any of its children’s children etc.
    #contains the given map.
    #==Parameter
    #[map] Either an ID or an instance of this class to check for.
    #==Return value
    #Either +true+ or +false+.
    def ancestor?(map)
      id = map.respond_to?(:to_int) ? map.to_int : map

      traverse do |child|
        return true if child.id == id
      end

      false
    end

    #Checks whether any of this map’s children is
    #the given map. This is not done recursively,
    #see #ancestor? for this.
    #==Parameter
    #[map] Either an ID or an instance of this class to check for.
    #==Return value
    #A truth value.
    def has_child?(map)
      id = map.respond_to?(:to_int) ? map.to_int : map
      @children.find{|map| map.id == id}
    end

    #Add a child map.
    #==Parameter
    #[map] An instance of this class.
    #==Raises
    #[ArgumentError] +map+ equals +self+.
    #==Return value
    #+map+.
    def add_child(map)
      raise(ArgumentError, "Someone can't be his own father!") if map == self

      @children << map
    end

    #Same as #add_child, but returns +self+ to allow method
    #chaining.
    #==Parameter
    #[map] The map to add.
    #==Raises
    #[ArgumentError] You tried to add +self+ as a child.
    #==Return value
    #+self+.
    def <<(map)
      add_child(map)
      self
    end

    #Delete a <b>child map</b>.
    #==Parameter
    #[map] Either the ID or the Map instance to delete.
    #==Raises
    #[ArgumentError] The given map is not a direct child of this map.
    def delete(map)
      id = map.respond_to?(:to_int) ? map.to_int : map
      raise(ArgumentError, "Child map not found: #{map}!") unless has_child?(id)

      # Deleting a child frees its ID, hence ensure that
      # no IDs are generated while a child is being deleted
      # (and the other way round, of course).
      @project.mutexes.map_id.synchronize{@children.delete_if{|child| child.id == id}}
    end

    #call-seq:
    #  traverse(include_self = false){|map| ...}
    #
    #Recursively iterates over this (optionally) and all child
    #maps.
    #==Parameters
    #[include_self] (false) If this is true, the block will be called
    #               once for +self+ before starting with the children.
    #[map]          (*Block*) The currently iterated child map, or,
    #               depending on the value of +include_self+, +self+.
    def traverse(include_self = false, &block)
      return enum_for __method__ unless block

      block.call(self) if include_self

      @children.each do |child|
        block.call(child)
        child.traverse(&block)
      end
    end

    #Same as ruby-tmx’ +to_xml+, but with a log message.
    #==Parameter
    #[path] Where to save the XML to.
    def save(path)
      logger.debug "Saving map to #{path}"
      to_xml(path)
    end

    private

    #Finds the first unused map ID and returns it.
    def generate_id
      @project.mutexes.map_id.synchronize do
        ids = []
        @project.root_maps.each do |root_map|
          root_map.traverse.each{|map| ids << map.id}
        end

        1.upto(Float::INFINITY) do |id|
          return id unless ids.include?(id)
        end
      end
    end

  end

end
