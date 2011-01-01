#!/usr/bin/env ruby
#Encoding: UTF-8

module OpenRubyRMK
  
  module Karfunkel
    
    #An object of this class represents a single opened or loading project.
    #When loading a project, the ::load method will spawn to subprocesses that
    #do the actual work of extracting the compressed files. You may always check
    #how for the already got by querying the loading attribute which gives you
    #a detailed view about which client has done how much.
    #Alternatively, you may just call #loaded? or #loading? if you're interested
    #wheather or not a project is fully loaded.
    class Project
      
      #ProjectPaths are pure informational objects. You can't do anything
      #with them beside querying them about what paths a
      #project uses. All paths are returned as Pathname instances.
      class ProjectPaths
        
        #A projcet's toplevel directory (i.e. the directory containing <b>bin/</b>).
        attr_reader :toplevel_dir
        #A project's temporary directory (i.e. where extracted mapsets and other things are stored).
        attr_reader :temp_dir
        
        #Creates a new ProjectPaths object. This is called internally by
        #Project.new. You won't have to use it.
        def initialize(toplevel_dir, temp_dir)
          @toplevel_dir = toplevel_dir
          @temp_dir = temp_dir
        end
        
        def maps_dir
          @toplevel_dir + "data" + "maps"
        end
        
        def maps_structure_file
          maps_dir + "structure.bin"
        end
        
        def mapsets_dir
          @toplevel_dir + "data" + "graphics" + "mapsets"
        end
        
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
      #  {:map_extraction => percent_done, :char_extraction => percent_done}
      attr_reader :loading
      
      def initialize
        #TODO
      end
      
      #Loads an existing project. Pass in the path to the project file,
      #i.e. the file ending in <tt>.rmk</tt>.
      #This method immediately returns, to check wheather the project is
      #already in a usable state, use #loaded?.
      def self.load(project_file)
        obj = allocate
        obj.instance_eval do
          @temp_dir = Pathname.new(Dir.mktmpdir("OpenRubyRMK"))
          at_exit do
            @temp_dir.rmtree
          end
          
          #Set the new project path
          #project_file is something like "/path/to/project/bin/project.rmk"
          @paths = ProjectPaths.new(project_file.dirname.parent, @temp_dir)
          #This is the name of the project we're now working on
          @name = project_file.basename.to_s.match(/\.rmk$/).pre_match
          
          #Extract mapsets and characters
          @loading = {:map_extraction => 0, :char_extraction => 0}
          #Spawn two processes for extracting and monitor what they're doing.
          #The treads are here, because I need to access the @loading hash
          #during load time without the need of a server.
          #And Ruby 1.9's threads rock! Not as good as processes, but we're
          #getting closer!
          Thread.new do
            r, w = IO.pipe #Works also on Windows ;-)
            spawn(
            Paths::RUBY,
            Paths::EXTRA_PROCESSES_DIR.join("mapset_extractor_client.rb").to_s,
            @paths.mapsets_dir,
            @paths.temp_mapsets_dir,
            out: w.fileno
            )
            while i = r.readline.chomp.to_i
              @loading[:map_extraction] = i
              break if i >= 100
            end
          end
          Thread.new do
            r, w = IO.pipe
            spawn(
            Paths::RUBY,
            Paths::EXTRA_PROCESSES_DIR.join("char_extractor_client.rb").to_s,
            @paths.characters_dir,
            @paths.temp_characters_dir,
            out: w.fileno
            )
            while i = r.readline.chomp.to_i
              @loading[:char_extraction] = i
              break if i >= 100
            end #while
          end #Thread.new
        end #instance_eval
      end #self.load
      
      #True if the project is fully loaded.
      def loaded?
        @loading.values.all?{|val| val >= 100}
      end
      
      #True if the project is currently loading.
      def loading?
        !loaded?
      end
      
    end
    
  end
  
end
