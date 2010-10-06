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

module OpenRubyRMK
  
  module Clients
    
    class CharExtractorClient
      
      def initialize(karfunkel_uri)
        @karfunkel_uri = karfunkel_uri
        DRb.start_service
        @karfunkel = DRbObject.new_with_uri(@karfunkel_uri)
      end
      
      def extract
        files = Dir.glob(@karfunkel.project_dirs[:project_characters_dir].join("**", "*.tgz").to_s).map{|f| Pathname.new(f)}
        num = files.length
        files.each_with_index do |filename, index|
          @karfunkel.log.debug("Extracting character '#{filename}'")
          temp_filename = @karfunkel.tempdirs[:temp_characters_dir] + filename.relative_path_from(@karfunkel.project_dirs[:project_characters_dir])
          gz = Zlib::GzipReader.open(filename)
          Archive::Tar::Minitar.unpack(gz, temp_filename.parent) ##unpack automatically closes the file
          @karfunkel.update_load_process($$, :char_extraction, (index + 1 / num).to_f)          
        end
      end
      
    end
    
  end
  
end
