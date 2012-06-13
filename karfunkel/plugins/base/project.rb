# -*- coding: utf-8 -*-

require_relative 'invalidatable'

module OpenRubyRMK::Karfunkel::Plugin::Base

  #Class for managing an OpenRubyRMK project.
  class Project
    include OpenRubyRMK::Karfunkel::Plugin::Helpers
    include OpenRubyRMK::Karfunkel::Plugin::Base::Invalidatable
    extend  OpenRubyRMK::Karfunkel::Plugin::Helpers

    #Struct encapsulating all the path information for a
    #single project.
    Paths = Struct.new(:root, :rmk_file, :data_dir, :maps_dir, :maps_file, :maps_dir, :tilesets_dir) do
      def initialize(root) # :nodoc:
        self.root         = Pathname.new(root).expand_path
        self.rmk_file     = self.root + "bin" + "#{self.root.basename}.rmk"
        self.data_dir     = self.root + "data"
        self.graphics_dir = data_dir + "graphics"
        self.maps_dir     = data_dir  + "maps"
        self.maps_file    = maps_dir  + "maps.xml"
        self.tilesets_dir = graphics_dir + "tilesets"
      end
    end

    #Struct encapsulating all per-project mutexes.
    Mutexes = Struct.new(:map_id) do
      def initialize # :nodoc:
        self.map_id = Mutex.new
      end
    end

    #The Paths struct belonging to this project.
    attr_reader :paths
    #The Mutexes struct belonging to this project.
    attr_reader :mutexes
    #This project’s main configuration, i.e. the parsed contents
    #of the +rmk+ file.
    attr_reader :config
    #The project’s root maps.
    attr_reader :root_maps
    #The project’s ID.
    attr_reader :id

    @project_id_mutex = Mutex.new
    @last_project_id  = 0

    #Threadsafely generate a new and unique ID usable for
    #a project. Called internally, you won’t need this.
    def self.generate_project_id # :nodoc:
      @project_id_mutex.synchronize do
        @last_project_id  += 1
      end
    end

    #Loads an OpenRubyRMK project from a project directory.
    #==Parameter
    #[path] The path to the project directory, i.e. the directory
    #       containing the bin/ subdirectory with the main RMK file.
    #==Return value
    #An instance of this class representing the project.
    def self.load(path)
      raise(ArgumentError, "Directory doesn't exist: #{path}!") unless File.directory?(path)

      proj = allocate
      proj.instance_eval do
        @paths       = Paths.new(path)
        @mutexes     = Mutexes.new
        @id          = self.class.generate_project_id
        @config      = YAML.load_file(@paths.rmk_file.to_s)
        @root_maps   = []
        @last_map_id = 0 # Set by #load_map apropriately

        xml = Nokogiri::XML(File.read(@paths.maps_file))
        xml.root.xpath("map").each do |node|
          @root_maps << load_map(self, node)
        end
      end

      log.info "Loaded project: #{proj.paths.root}"
      proj
    end

    #Creates a new project directory at the given path. This method
    #will copy the files from the skeleton archive (see Paths::SKELETON_FILE)
    #into that directory and then load the resulting project.
    #==Parameter
    #Path where to create a new project directory.
    #==Return value
    #A new instance of this class representing the created project.
    def initialize(path)
      @paths       = Paths.new(path)
      @mutexes     = Mutexes.new
      @id          = self.class.generate_project_id
      create_skeleton
      @config      = YAML.load_file(@paths.rmk_file.to_s)
      @root_maps   = []
      @last_map_id = 0

      log.info "Created project: #{@paths.root}"
    end

    #Recursively deletes the project directory and invalidates this
    #object. Do not use it anymore after calling this.
    def delete!
      # 1. Remove the project directory
      @paths.root.rmtree

      # 2. Inform the log
      log.info "Deleted project: #{@paths.root}"

      # 3. Commit suicide
      invalidate!
    end

    def save
      # Save the maps
      File.open(@paths.maps_file, "w") do |file|
        builder = Nokogiri::XML::Builder.new do |xml|
          xml.maps do |node|
            @root_maps.each{|map| save_map(map, node)}
          end
        end
        file.write(builder.to_xml)
      end

      # TODO: What other things to save?
    end

    #Threadsafely generates a new and unused map ID.
    def generate_map_id
      @mutexes.map_id.synchronize do
        @last_map_id += 1
      end
    end

    private

    #Extracts the skeleton archive into the project directory
    #and renames the name_of_proj.rmk file to the project’s name.
    def create_skeleton
      log.debug "Creating project directory skeleton in #{@paths.root}"
      Zlib::GzipReader.open(OpenRubyRMK::Karfunkel::Paths::SKELETON_FILE.to_s) do |tgz|
        Archive::Tar::Minitar.unpack(tgz, @paths.root.to_s)
      end
      File.rename(@paths.root.join("bin", "name_of_proj.rmk"), @paths.rmk_file)
    end

    #Recursive method adding an entry to +node+ for the given
    #+map+, saving the map to a map file and then calling itself
    #for each child map of +map+.
    #
    #Used by #save.
    def save_map(map, node)
      map.save

      node.map(name: map.name, id: map.id) do |child_node|
        map.children.each{|child_map| convert_map_to_xml(child_map, child_node)}
      end
    end

    #Recursively transforms +node+ into an instance
    #of class Map with child Map instances.
    #Called from ::load.
    def load_map(project, node)
      map = Map.load(project,
                     node["name"],
                     @paths.maps_dir.join("%04d.tmx" % node["id"].to_i))

      # Ensure that the map ID generator doesn’t yield
      # IDs already used by the last run.
      @mutexes.map_id.synchronize do
        @last_map_id = map.id if @last_map_id < map.id
      end

      node.xpath("map").each do |child_node|
        load_map(project, map, child_node).parent = map
      end

      map
    end

  end

end
