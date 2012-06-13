# -*- coding: utf-8 -*-
# File coping with maps. Note the bidirectional relationship
# between a map and its parent map -- both know about each
# other, one via #children, the other one via #parent. When
# modifying these relationships, *always* remember updating
# *both* sides of the relationship to prevent fatal errors!
# There are four places where the relationship is affected:
#
# * Map creation (#initialize).
#   Parent gains a new child, child sets parent.
# * Map loading (::load).
#   Same as above.
# * Reparenting (#parent=)
#   Old relationship is dissolved, new one established.
# * Deletion (#delete).
#   Parent looses a child, child is destroyed.

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

    #The parent map or +nil+ if this is a root map.
    attr_reader :parent

    #The Project instance this map belongs to.
    attr_reader :project

    #Loads a map from the XML file at the given +path+.
    #This is the same as ruby-tmx’ +load_xml+ method, but
    #includes a log message.
    #==Parameters
    #[project] The project this map is intended for.
    #[name]    The name for the map.
    #[path]    The location of the XML file to load.
    #==Return value
    #An instance of this class.
    #==Remarks
    #The TMX map files don’t know about map hierarchies,
    #meaning that this method will give you a parent-
    #and childless root map. Call #parent= on the returned
    #instance to assign it its place in the map hierarchy.
    def self.load(project, name, path)
      log.debug "Loading map from #{path}"
      obj = load_xml(path)
      obj.instance_eval do
        @project  = project
        @id       = File.basename(path).to_s.to_i # Pathname("foo/0004.tmx") -> Pathname("0004.tmx") -> "0004.tmx" -> 4
        @name     = name
        @children = []
        @parent   = nil
        @mutex    = Mutex.new
      end

      obj
    end

    #Creates a new instance of this class.
    #==Parameters
    #[project] The project to add this map to.
    #[name]    The name of the map.
    #[*args]   Passed on to <tt>TiledTmx::Map.new</tt>.
    #==Return value
    #An instance of this class.
    #==Remarks
    #Note that the unique ID is threadsafely generated
    #automatically <b>from the currently selected
    #project</b>, i.e. OpenRubyRMK::Karfunkel#active_project.
    #If you want to create a map for another project, you
    #have to activate it first.
    #
    #Calling this method gives you a parentless map, i.e.
    #a root map. You then have to call #parent= to assign
    #a parent map.
    def initialize(project, name = nil, *args)
      log.info "Creating a new map"
      super(*args)
      @project  = project
      @id       = @project.generate_map_id
      @name     = name || "Map_#@id"
      @children = []
      @parent   = nil
      @mutex    = Mutex.new

      #Create the map file
      save
    end

    #Equality test. Two maps are considered equal if their
    #IDs are the same.
    def eql?(other)
      return false unless other.respond_to?(:project) and other.respond_to?(:id)

      @project == other.project && @id == other.id
    end
    alias == eql?

    #Ruby hook called by +dup+ and +clone+. For this class,
    #it generates a new map ID instead of copying that one
    #from the old map (which would cause heavy confusion!)
    #and forbids child maps to be copied (a map can only
    #have *one* parent!).
    def initialize_copy(other)
      @id       = @project.generate_map_id
      @children = []
    end

    #Human-readable description of form:
    #  #<OpenRubyRMK::Karfunkel::Plugins::Base::Project <mapname> (<id>) with <num> children>
    def inspect
      "#<#{self.class} #@name (#@id) with #{@children.count} children>"
    end

    #Correctly dissolves the relationship between this
    #map and its old parent (if any), then establishes
    #the new relationship to the new parent.
    def parent=(map)
      # Unless we’re a root map, delete us from the
      # old parent.
      @parent.children.delete(self) if @parent

      @mutex.synchronize do
        # Unless we’re made a root map now, add us to the
        # new parent.
        map.children << self if map

        # Update our side of the relationship.
        @parent = map
      end
    end

    #Checks whether a map is somewhere an ancestor of
    #another, i.e. any of its children’s children etc.
    #contains the given map.
    #==Parameter
    #[map] Either an ID or an instance of this class to check for.
    #==Return value
    #Either +true+ or +false+.
    def ancestor?(map)
      id = map.kind_of?(self.class) ? map.id : map

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
      id = map.kind_of?(self.class) ? map.id : map
      @children.find{|map| map.id == id}
    end

    #Checks whether this is a root map and if so,
    #returns true, otherwise false. A root map is
    #a map without a parent map.
    def root?
      @parent.nil?
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

    #Path where this map gets saved to.
    def path
      @project.paths.maps_dir.join("%04d.tmx" % @id)
    end

    #Dissolves the relationship between this map and its
    #parent (if any), removes the map file and recursively
    #repeats this process for its child maps.
    #==Remarks
    #If this map was a root map previously, ensure that
    #you remove it from the list of root maps now.
    def delete
      self.parent = nil # Grabs the mutex on its own
      self.path.delete
      @children.each{|child| child.delete}
    end

    #Calls ruby-tmx’ +to_xml+, logs the call and writes the
    #result out to a file derived from the map’s project.
    def save
      log.debug "Saving map to #{path}"
      File.open(path, "w"){|f| f.write(to_xml)} # FIXME: Ensure this works with a future version of ruby-tmx, this is subject to change
    end

  end

end
