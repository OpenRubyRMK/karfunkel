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
  
  #This module contains various OpenRubyRMK-related error classes.
  #Errors which always cause the same message to be emmited, support a
  #<tt>throw!</tt> class method.
  module Errors
    
    #Superclass of every error specific to OpenRubyRMK.
    class OpenRubyRMKError < StandardError
    end

    #Raised when errors in the configuration file are detected.
    class ConfigurationError < OpenRubyRMKError
    end

    #Raises when something plugin-related has gone wrong.
    class PluginError < OpenRubyRMKError
    end

    #Something was wrong with a mapset file.
    class InvalidMapsetError < OpenRubyRMKError
    end
    
    class InvalidCommand < OpenRubyRMKError
    end
    
    class MalformedCommand < InvalidCommand
    end

    class UnknownRequestType < InvalidCommand

      attr_reader :request

      def initialize(request, message)
        super(message)
        @request = request
      end

    end

    class UnknownResponseType < InvalidCommand

      attr_reader :response

      def initialize(response, message)
        super(message)
        @response = response
      end

    end

    class UnknownNotificationType < InvalidCommand

      attr_reader :notification

      def initialize(note, message)
        super(message)
        @notification = note
      end

    end

    class InvalidParameter < MalformedCommand
    end
    
    class AuthenticationError < OpenRubyRMKError
    end
    
    class ConnectionFailed < OpenRubyRMKError
    end
    
  end
  
end
