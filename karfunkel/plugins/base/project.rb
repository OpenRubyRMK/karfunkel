# -*- coding: utf-8 -*-

#Class for managing an OpenRubyRMK project.
class OpenRubyRMK::Karfunkel::Plugin::Base::Project
  include OpenRubyRMK::Karfunkel::Plugin::Helpers
  extend  OpenRubyRMK::Karfunkel::Plugin::Helpers

  #Struct encapsulating all the path information for a
  #single project.
  Paths = Struct.new(:root, :rmk_file, :data_dir, :maps_dir, :maps_file) do
    def initialize(root) # :nodoc:
      @root = Pathname.new(root).expand_path
      @rmk_file = @root + "bin" + "#{@root.basename}.rmk"
      @data_dir = @root + "data"
      @maps_dir = @data_dir + "graphics" + "maps"
      @map_file = @maps_dir + "maps.xml"
    end
  end

  #Struct encapsulating all per-project mutexes.
  Mutexes = Struct.new(:map_id) do
    def initialize # :nodoc:
      instance_variables.each{|ivar| instance_variable_set(ivar, Mutex.new)}
    end
  end

  #The Paths struct belonging to this project.
  attr_reader :paths
  #The Mutexes struct belonging to this project.
  attr_reader :mutexes
  #This project’s main configuration, i.e. the parsed contents
  #of the +rmk+ file.
  attr_reader :config
  #The project’s ID.
  attr_reader :id

  @project_id_mutex = Mutex.new
  @last_project_id  = 0

  class << self

    #Threadsafely generate a new and unique ID usable for
    #a project. Called internally, you won’t need this.
    def generate_project_id # :nodoc:
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
    def load(path)
      raise(ArgumentError, "Directory doesn't exist: #{path}!") unless File.directory?(path)

      proj = allocate
      proj.instance_eval do
        @paths   = Paths.new(path)
        @mutexes = Mutexes.new
        @id      = self.class.generate_project_id
        @config  = YAML.load_file(@paths.rmk_file.to_s)

        @root_maps = []
        xml = Nokogiri::XML(File.read(@config.maps_file))
        xml.root.children.each do |node|
          @root_maps << load_map(node)
        end
      end

      logger.info "Loaded project: #{@paths.root}"
      proj
    end

    private

    #Recursively transforms +map_node+ into an instance
    #of class Map with child Map instances.
    #Called from ::load.
    def load_map(map_node)
      map = OpenRubyRMK::Plugins::Base::Map.load(@paths.maps_dir.join("#{node['id']}.tmx"))

      map_node.children.each do |child_node|
        map.add_child(load_map(map, child_node))
      end

      map
    end
  end

  #Creates a new project directory at the given path. This method
  #will copy the files from the skeleton archive (see Paths::SKELETON_FILE)
  #into that directory and then load the resulting project.
  #==Parameter
  #Path where to create a new project directory.
  #==Return value
  #A new instance of this class representing the created project.
  def initialize(path)
    @paths     = Paths.new(path)
    @mutexes   = Mutexes.new
    @id        = self.class.generate_project_id
    @path.mkpath
    create_skeleton
    @config    = YAML.load_file(@paths.rmk_file.to_s)
    @root_maps = []

    logger.info "Created project: #{@paths.root}"
  end

  #Recursively deletes the project directory and invalidates this
  #object. Do not use it anymore after calling this.
  def delete!
    # 1. Remove the project directory
    @paths.root.rmtree

    # 2. Inform the log
    logger.info "Deleted project: #{@paths.root}"

    # 3. Commit suicide
    instance_variables.each{|ivar| instance_variable_set(ivar, nil)}
  end

  def save
    # Save the maps
    File.open(@paths.maps_file, "w") do |file|
      Nokogiri::XML::Builder.new do |xml|
        xml.maps do |node|
          @root_maps.each{|map| save_map(map, node)}
        end
      end
    end

    # TODO: What other things to save?
  end

  private

  #Extracts the skeleton archive into the project directory
  #and renames the name_of_proj.rmk file to the project’s name.
  def create_skeleton
    logger.debug "Creating project directory skeleton for #@path"
    Zlib::GzipReader.open(OpenRubyRMK::Karfunkel::Paths::SKELETON_FILE.to_s) do |tgz|
      Minitar.unpack(tgz, @path.to_s)
    end
    File.rename(@path.join("bin", "name_of_proj.rmk"), "#{@path.basename}.rmk")
  end

  #Recursive method adding an entry to +xml_node+ for the given
  #+map+, saving the map to a map file and then calling itself
  #for each child map of +map+.
  #
  #Used by #save.
  def save_map(map, xml_node)
    map.save(@paths.maps_dir.join("#{node['id']}.tmx"))

    xml_node.map(name: map.name, id: map.id) do |child_node|
      map.children.each{|child_map| convert_map_to_xml(child_map, child_node)}
    end
  end

end
