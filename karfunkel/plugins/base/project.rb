# -*- coding: utf-8 -*-

#Class for managing an OpenRubyRMK project.
class OpenRubyRMK::Karfunkel::Plugin::Base::Project

  #The path to the project directory.
  attr_reader :path
  #This project’s main configuration, i.e. the parsed contents
  #of the +rmk+ file.
  attr_reader :config
  #The project’s ID.
  attr_reader :id

  @id_mutex = Mutex.new

  #Threadsafely generate a new and unique ID usable for
  #a project. Called internally, you won’t need this.
  def self.generate_id # :nodoc:
    @id_mutex.synchronize do
      @last_id ||= 0
      @last_id  += 1
    end
  end

  #Loads an OpenRubyRMK project from a project directory.
  #==Parameter
  #[path] The path to the project directory, i.e. the directory
  #       containing the bin/ subdirectory with the main RMK file.
  #==Return value
  #An instance of this class representing the project.
  def self.load(path)
    proj = allocate
    proj.instance_eval do
      @path   = Pathname.new(path)
      @config = YAML.load_file(@path.join("bin", "#{@path.basename}.rmk").to_s)
    end

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
    @path = Pathname.new(path).expand_path
    @id   = self.class.generate_id
    @path.mkpath
    create_skeleton
    @config = YAML.load_file(@path.join("bin","#{@path.basename}.rmk").to_s)
  end

  #Recursively deletes the project directory and invalides this
  #object. Do not use it anymore after calling this.
  def delete!
    @path.rmtree
    @path   = nil
    @config = nil
    @id     = nil
  end

  private

  #Extracts the skeleton archive into the project directory
  #and renames the name_of_proj.rmk file to the project’s name.
  def create_skeleton
    Zlib::GzipReader.open(OpenRubyRMK::Karfunkel::Paths::SKELETON_FILE.to_s) do |tgz|
      Minitar.unpack(tgz, @path.to_s)
    end
    File.rename(@path.join("bin", "name_of_proj.rmk"), "#{@path.basename}.rmk")
  end

end
