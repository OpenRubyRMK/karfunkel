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
  
  module Karfunkel
    
    module ServerManagement
      
      #This module handles command-line switches passed to Karfunkel.
      #At startup time, the OptionHandler.parse method is called with
      #the arguments passed to the program (usually the ARGV array) which
      #gets parsed and the results are saved in the OptionHandler.options
      #hash. Options that weren't passed are mapped to a default value.
      #
      #The most private methods of this module are option handlers, i.e. whenever
      #an option is encountered, the associated option handler is called.
      module OptionHandler
        
        class << self
          
          #Parses the given array as a list of command-line options.
          #Returns a hash that states how the passed options have been understood.
          #This is the same hash as returned by ::options.
          def parse(args)
            #Default values for those options that can be
            #specified SOLELY through command-line arguments and
            #CANNOT be changed via the configuration file.
            @options = {
              :debug => false
            }
            
            options = OptionParser.new do |opts|
              opts.banner = banner
              
              opts.on("-c", "--configfile FILE", "Uses FILE as the configuration file."){|file| on_configfile(file)}
              opts.on("-d", "--[no-]debug", "Show debugging information on run."){|bool| on_debug(bool)}
              opts.on("-h", "--help", "Display this help message and exit."){on_help(opts)}
              opts.on("-l", "--logdir DIR", "Log messages to files in DIR."){|dir| on_logdir(dir)}
              opts.on("-L", "--loglevel LEVEL", Integer, "Set the logging level to LEVEL."){|level| on_loglevel(level)}
              opts.on("-s", "--stdout", "Logs to STDOUT. Cannot be used with -l."){on_stdout}
              opts.on("-v", "--version", "Print version and exit."){on_version}
              opts.on("-V", "--[no-]verbose", "Show additional information on run.", "  Shortcut for -L1."){|bool| on_verbose(bool)}
            end
            
            options.parse!(args)
            @options
          end
          
          #A hash containing all parsed command-line options in this form:
          #  {:option => value, ...}
          #:option is always a symbol, value's class depends on the option.
          #Not-given options are mapped to default values.
          #
          #Make sure you have called the ::parse method before calling this one.
          def options
            @options
          end
          
          private
          
          #The banner displayed ontop of the help message.
          def banner
            <<-EOF
            USAGE:
            karfunkel [-V] [-d] [-l [FILE]] [-L LEVEL]
            
            DESCRIPTION
            Karfunkel is the server component of the OpenRubyRMK.
            OpenRubyRMK is a free and open-source RPG creation program. If you find any
            bugs, please let us know via the mail address openrubyrmk@googlemail.com
            or file a bug at https://github.com/Quintus/OpenRubyRMK/issues.
            Below is a summary of possible command-line options, but please note that
            the -s, -l, and -L options don't have any effect when -d is passed. It is
            not possible to combine the short options into someting like -sV as the
            tar command allows. You have to pass them separately, for instance as -s -V.
            
            Note there is also a configuration file where you can put most of the
            things you can specify via the command-line into to make them persistent.
            The default config file for Karfunkel is
            <OpenRubyRMKDir>/config/OpenRubyRMK-rc.yml
            and if the values set in it conflicht with what you specify on the
            command-line, the command-line arguments are preferred.
            
            The possible logging levels for the -L option are:
            0 - Debug. Do not use.
            1 - Info. Logs much information on what's going on.
            2 - Warn. This is the default; logs only warnings and errors.
            3 - Error. Log only errors.
            4 - Fatal. Log only errors that cause Karfunkel to crash.
            5 - Unknown. Suppresses any logging. Shouldn't be used.
            
            EXAMPLES
            Show additional information on the console while running
            karfunkel -s -V
            
            Same as above
            karfunkel -s -L1
            
            Log only fatal errors
            karfunkel --loglevel=4
            
            Log only fatal errors, change the log dir
            karfunkel -l /home/freak/logs/ -L4
            
            Same as above
            karfunkel --logdir=/home/freak/logs/ --loglevel=4
            
            Use another configuration file
            karfunkel -c /home/freak/myconfig.yml
            
            OPTIONS
            EOF
          end
          
          def on_stdout
            @options[:stdout] = true
          end
          
          def on_configfile(file)
            @options[:configfile] = file
          end
          
          def on_verbose(bool)
            @options[:loglevel] = Logger::INFO if bool
          end
          
          def on_debug(bool)
            @options[:debug] = bool
          end
          
          def on_version
            puts "This is OpenRubyRMK, version #{OpenRubyRMK::VERSION}."
            exit
          end
          
          def on_logdir(dir)
            @options[:logdir] = dir
          end
          
          def on_loglevel(level)
            @options[:loglevel] = level
          end
          
          def on_help(opts)
            puts opts
            exit
          end
          
        end
        
      end
      
    end
    
  end
  
end
