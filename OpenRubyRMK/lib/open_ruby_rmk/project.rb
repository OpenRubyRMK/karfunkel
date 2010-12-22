#!/usr/bin/env ruby
#Encoding: UTF-8

module OpenRubyRMK
  
  module Karfunkel
    
    class Project
      
      #ProjectPaths are pure informational objects. You can't do anything 
      #with them beside querying them about what paths a 
      #project uses. All paths are returned as Pathname instances. 
      class ProjectPaths
        
        #A projcet's toplevel directory (i.e. the directory containing <b>bin/</b>). 
        attr_reader :toplevel
        #A project's temporary directory (i.e. where extracted mapsets and other things are stored).
        attr_reader :temp_dir
        
        #Creates a new ProjectPaths object. This is called internally by 
        #Project.new. You won't have to use it. 
        def initialize(toplevel_dir, temp_dir)
          @toplevel = toplevel_dir
          @temp_dir = temp_dir
        end
        
        def toplevel_dir
          @toplevel
        end
        
        def maps_dir
          @toplevel + "data" + "maps"
        end
        
        def maps_structure_file
          maps_dir + "structure.bin"
        end
        
        def mapsets_dir
          @toplevel + "data" + "graphics" + "mapsets"
        end
        
        def characters_dir
          @toplevel + "data" + "graphics" + "characters"
        end
        
        def temp_mapsets_dir
          @temp_dir + "mapsets"
        end
        
        def temp_characters_dir
          @temp_dir + "characters"
        end
        
      end
      
      #This is an object of class Karfunkel::Project::Paths which holds 
      #information about the path a single project uses. 
      attr_reader :paths
      
      #Loads an existing project. Pass in the path to the project file, 
      #i.e. the file ending in <tt>.rmk</tt>. 
      def self.load(project_file)
        @temp_dir = Pathname.new(Dir.mktmpdir("OpenRubyRMK"))
        Karfunkel.instance.log("Created temporary directory '#{@temp_dir}'.")
        at_exit do
          Karfunkel.instance.log.debug("Removing temporary directory '#{@temp_dir}'.")
          @temp_dir.rmtree
        end
                
        #Set the new project path
        #project_file is something like "/path/to/project/bin/project.rmk"
        @paths = ProjectPaths.new(project_file.dirname.parent, @temp_dir)
        #This is the name of the project we're now working on
        @name = project_file.basename.to_s.match(/\.rmk$/).pre_match
        #Extract mapsets and characters
        @loading = {:map_extraction => 0, :char_extraction => 0}
        @allowed_pids.clear        
        @allowed_pids << spawn(RUBY, OpenRubyRMK::Paths::BIN_CLIENTS_DIR.join("mapset_extractor_client.rb").to_s, Karfunkel.instance.uri)      
        @allowed_pids << spawn(RUBY, OpenRubyRMK::Paths::BIN_CLIENTS_DIR.join("char_extractor_client.rb").to_s, Karfunkel.instance.uri)
        
        #Notify the server we have a new project now (even if it's not fully loaded it's there)
        Karfunkel.instance.register_project(self)
      end
      
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
