#!/usr/bin/env ruby
#Encoding: UTF-8

=begin
This file is part of OpenRubyRMK. 

Copyright © 2010 OpenRubyRMK Team

OpenRubyRMK is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

OpenRubyRMK is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with OpenRubyRMK.  If not, see <http://www.gnu.org/licenses/>.
=end

require "bundler/setup"
require "pathname"
require "archive/tar/minitar"
require "zlib"
require "drb"

module OpenRubyRMK
  
  module Clients
    
    class MapsetExtractorClient
      
      def initialize(karfunkel_uri)
        @karfunkel_uri = karfunkel_uri
        DRb.start_service
        @connection = DRbObject.new_with_uri(@karfunkel_uri)
        @remote_rmk = @connection.remote_rmk
      end
      
      def extract
        paths = @remote_rmk.const_get(:Paths)
        
        files = Dir.glob(paths.project_mapsets_dir].join("**", "*.tgz").to_s).map{|f| Pathname.new(f)}
        num = files.length
        files.each_with_index do |filename, index|
          @connection.log.debug("[Mapset extractor (#$$)] Extracting map '#{filename}'")
          temp_filename = paths.temp_mapsets_dir + filename.relative_path_from(paths.project_mapsets_dir])
          gz = Zlib::GzipReader.open(filename)
          Archive::Tar::Minitar.unpack(gz, temp_filename.parent) ##unpack automatically closes the file
          @connection.update_load_process($$, :map_extraction, (index + 1 / num).to_f)          
        end
      end
      
    end
    
  end
  
end
