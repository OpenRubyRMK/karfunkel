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

module OpenRubyRMK
  
  module GUI
    
    #According to the wxRuby docs, a GridTableBase is the "database" of a Grid. 
    #Following this explanation, this class supploes the Grid control used in the 
    #mapset window with data, i.e. with images based on the underlying mapset. 
    #
    #The relationships are as follows: 
    #A Grid control gets it's data from the associated GridTableBase. The data 
    #is displayed via a per-cell renderer which is found out by querying the GridTableBase 
    #for a cell's type. For our example, MapsetTableBase will return "MAP_FIELD" as the type 
    #which in turn can be rendered by the FieldRenderer class. 
    class MapsetTableBase < Wx::GridTableBase
      include Wx
      
      #The mapset associated with this GridTableBase. 
      attr_reader :mapset
      
      #Creates a new "database". Pass in the mapset you want to display. 
      def initialize(mapset)
        super()
        @mapset = mapset
      end
      
      def get_number_rows
        @mapset.rows
      end
      
      def get_number_cols
        @mapset.columns
      end
      
      def get_value(row, col)
        @mapset[row, col]
      end
      
      def get_type_name(row, col)
        GRID_FIELD_TYPE
      end
      
      def get_attr(row, col, attr_kind)
        attr = GridCellAttr.new
        attr.read_only = true
        attr
      end
      
      def is_empty_cell(row, col)
        false #No empty cells - even transparent ones contain something. 
      end
      
    end
    
  end
  
end