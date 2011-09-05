#!/usr/bin/env ruby
#Encoding: UTF-8

module OpenRubyRMK
  
  module Karfunkel
    
    module ProjectManagement
      
      #An object of this class represents a single opened or loading project.
      #When loading a project, the ::load method will create threads that
      #do the actual work of extracting the compressed files. You may always check
      #how far they already got by querying the loading attribute which gives you
      #a detailed view about which client has done how much.
      #Alternatively, you may just call #loaded? or #loading? if you're
      #interested in wheather or not a project is fully loaded.
      class Project
        
        #ProjectPaths are pure informational objects. You can't do anything
        #with them beside querying them about what paths a
        #project uses. All paths are returned as Pathname instances.
        class ProjectPaths
          
          #A project's toplevel directory (i.e. the directory containing <b>bin/</b>).
          attr_reader :toplevel_dir
          #A project's temporary directory (i.e. where extracted mapsets and other things are stored).
          attr_reader :temp_dir
          #A project's main file.
          attr_reader :project_file
          
          #Creates a new ProjectPaths object. This is called internally by
          #Project.new. You won't have to use it.
          def initialize(project_file, temp_dir)
            @project_file = project_file
            @toplevel_dir = project_file.dirname.parent
            @temp_dir = temp_dir
          end
          
          #The directory complete maps are saved to.
          def maps_dir
            @toplevel_dir + "data" + "maps"
          end
          
          #The file describing the map structure.
          def maps_structure_file
            maps_dir + "structure.bin"
          end
          
          #The directory mapsets are saved to.
          def mapsets_dir
            @toplevel_dir + "data" + "graphics" + "mapsets"
          end
          
          #The directory character graphcis are saved to.
          def characters_dir
            @toplevel_dir + "data" + "graphics" + "characters"
          end
          
          def temp_mapsets_dir
            @temp_dir + "mapsets"
          end
          
          def temp_characters_dir
            @temp_dir + "characters"
          end
          
        end
        
        #This is an object of class Project::Paths which holds
        #information about the path a single project uses.
        attr_reader :paths
        #The state of a loading project. A hash of form
        #  {:mapset_extraction => percent_done, :char_extraction => percent_done}
        attr_reader :loading
        #The name of the project, obtained from the project file's name.
        attr_reader :name
        #All Maps of a project.
        attr_reader :maps
        #This is an array of all mapsets this project deals with.
        attr_reader :mapsets
        
        def initialize
          #TODO
        end
        
        #Loads an existing project. Pass in the path to the project file,
        #i.e. the file ending in <tt>.rmk</tt>.
        #This method immediately returns, to check wheather the project is
        #already in a usable state, use #loaded?.
        def self.load(project_file)
          project_file = Pathname.new(project_file)
          raise(ArgumentError, "Project file not found: '#{project_file}'!") unless project_file.file?
          obj = allocate
          obj.instance_eval do
            @temp_dir = Pathname.new(Dir.mktmpdir("OpenRubyRMK"))
            at_exit do
              @temp_dir.rmtree
            end
            
            #Set the new project path.
            #project_file is something like "/path/to/project/bin/project.rmk"
            @paths = ProjectPaths.new(project_file, @temp_dir)
            #This is the name of the project we're now working on
            @name = project_file.basename.to_s.match(/\.rmk$/).pre_match
            #This is a list of all mapsets available in this project.
            @mapsets = []
            #This is a list of all maps that have already been built with this
            #project.
            @maps = []
            
            #Extract mapsets and characters. This hash is a shared
            #resource, but since every thread updates another part of
            #it, there's no mutex needed.
            @loading = {:mapset_extraction => 0, :char_extraction => 0}
            
            #Extract the mapsets.
            Thread.new do
              files = @paths.mapsets_dir.glob("**/*.tgz")
              num = files.count
              files.each_with_index do |filename, index|
                temp_filename = @paths.temp_mapsets_dir + filename.relative_path_from(@paths.mapsets_dir)
                gz = Zlib::GzipReader.open(filename)
                Archive::Tar::Minitar.unpack(gz, temp_filename.parent) ##unpack automatically closes the file
                @mapsets << Mapset.load(filename.basename.to_s.sub(/\.tgz$/, ".png"))
                #Show the % done
                @loading[:mapset_extraction] = (index + 1 / num).to_f * 100
              end
            end
            
            #Extract the characters.
            Thread.new do
              files = @paths.characters_dir.glob("**/*.tgz")
              num = files.count
              files.each_with_index do |filename, index|
                temp_filename = @paths.temp_characters_dir + filename.relative_path_from(@paths.characters_dir)
                gz = Zlib::GzipReader.open(filename)
                Archive::Tar::Minitar.unpack(gz, temp_filename.parent) ##unpack automatically closes the file
                #No need to reference the characters, this is done by the maps.
                
                #Show % done
                @loading[:char_extraction] = (index + 1 / num).to_f * 100
              end
            end
            
          end #instance_eval
          obj
        end #self.load
        
        #True if the project is fully loaded.
        def loaded?
          @loading.values.all?{|val| val >= 100}
        end
        
        #True if the project is currently loading.
        def loading?
          !loaded?
        end
        
        #Two projects are considered equal when they refer to the
        #same project file.
        def ==(other)
          return false unless other.respond_to? :paths
          return false unless other.paths.respond_to? :project_file
          @paths.project_file == other.paths.project_file
        end
        alias eql? ==
        
        #Human-readable description of form
        #  #<OpenRubyRMK::Karfunkel::ProjectManagement::Project <project_name>>
        def inspect
          "#<#{self.class} #{@name}>"
        end
        
      end
      
    end
    
  end
  
end
