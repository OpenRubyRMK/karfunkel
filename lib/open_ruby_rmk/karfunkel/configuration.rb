# -*- coding: utf-8 -*-
# This file is part of OpenRubyRMK.
# 
# Copyright © 2012 OpenRubyRMK Team
# 
# OpenRubyRMK is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
# 
# OpenRubyRMK is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with OpenRubyRMK.  If not, see <http://www.gnu.org/licenses/>.

#Base configuration facility of Karfunkel. The configuration file’s
#main block is evaluated inside the context of an instance of this
#class. Note that this class is just a storage for any kind of
#configuration information, it doesn’t validate what is assigned to
#it. The validation is responsibility of the respective plugins that
#handle the configuration options (even if it’s just the +base+ plugin).
#
#The methods in this class are mainly interesting for the configuration
#DSL, but if you want to change configuration options later on you
#can use them of course.
#
#See the Karfunkel class’ documention for information on creating
#sub-plugins for classes like this.
#
#Note that each and every option must have a useful default value
#(hook into #default_values for adding new ones), because Karfunkel
#uses this to reject unknown configuration options. Use +nil+ as the
#default value if you don’t know what else to specify.
class OpenRubyRMK::Karfunkel::Configuration
  extend OpenRubyRMK::Karfunkel::Pluggable

  #The underlying configuration hash.
  attr_reader :config

  #Creates a new instance of this class.
  #==Return value
  #The newly created instance.
  def initialize
    @config = {}
  end

  #Returns the value of the given option.
  #==Parameter
  #[option] The option to read, any object responding to #to_sym.
  #==Return value
  #The option’s value or +nil+ if the option is unset.
  def [](option)
    @config[option.to_sym]
  end

  #Sets the value of the given option.
  #==Parameters
  #[option] The option to set, any object responding to #to_sym.
  #[value]  The value to set.
  def []=(option, value)
    @config[option.to_sym] = value
  end

  #Checks the configuration for unknown options.
  #==Raises
  #[Errors::ConfigurationError]
  #  If an unknown option, i.e. one that has
  #  no specified default value, is found.
  def check!
    defaults = default_values
    @config.keys.each do |option|
      unless defaults.has_key?(option)
        raise(OpenRubyRMK::Errors::ConfigurationError, "Unknown configuration option '#{option}'.")
      end
    end
  end

  #call-seq:
  #  each           → an_enumerator
  #  each{|ary|...}
  #
  #Iterates over the internal configuration hash, yielding a two-element
  #array containing the option name and value.
  def each(&block)
    @config.each(&block)
  end

  #call-seq:
  #  each_pair                     → an_enumerator
  #  each_pair{|option, value|...}
  #
  #Iterates over the internal configuration hash, yielding each option
  #and the corresponding value to the block.
  def each_pair(&block)
    @config.each_pair(&block)
  end

  #call-seq:
  #  each_changed_pair                     → an_enumerator
  #  each_changed_pair{|option, value|...}
  #
  #Same as #each_pair except it only iterates over those options that
  #differ from the default values, i.e. have been changed by the user.
  #See also #changed_options.
  def each_changed_pair
    return enum_for(__method__) unless block_given?

    defaults = default_values
    @config.each_pair do |option, value|
      yield(option, value) unless defaults[option] == value
    end
  end

  #A hash of all options and their corresponding values that have been
  #changed from the defaults. See also #each_changed_pair.
  def changed_options
    result = {}
    each_changed_pair{|option, value| result[option] = value}
    result
  end

  pluggify do

    #*Hook*. The default values for most options, i.e. the
    #values they have prior to any setting. The default
    #implementation defines the default values for the options
    #constrolling the server’s default behaviour, i.e. it sets
    #the default values for the options available in the default
    #implementation of Karfunkel#parse_argv.
    #This method must return a hash using symbols as keys.
    #==Example
    #  module MyPlugin
    #    module Configuration
    #      def default_values
    #        super.merge({:cool_option => 10})
    #      end
    #    end
    #  end
    def default_values
      {
        :port          => 3141,
        :log_level     => 1,
        :log_format    => lambda{|sev, time, progname, msg| time.strftime("%d/%m/%Y %H:%M:%S [#{sev.chars.first}] #{msg}\n")},
        :ping_interval => 20,
        :greet_timeout => 5,
        :pid_file      => OpenRubyRMK::Karfunkel::Paths::TMP_DIR + "karfunkel.pid",
        :signal_pid    => nil,
      }
    end

  end

  #Set the given option to the given value.
  #==Parameters
  #[option] The option to set. Usually a symbol, but accepts any object
  #         responding to #to_sym.
  #[value]  The value to set.
  def set(option, value)
    @config[option.to_sym] = value
  end

  #Enables the given option. Equivalent to:
  #  set(option, true)
  def enable(option)
    set(option, true)
  end

  #Disables the given option. Equivalent to:
  #  set(option, false)
  def disable(option)
    set(option, false)
  end

  #Associates the given option with a Ruby block. Equivalent to:
  #  set(option, lambda{block_code_here})
  def define(option, &block)
    set(option, block)
  end

  #Allows to reference an option’s value by using the option’s name.
  #If the option doesn’t exist raises an instance of
  #Errors::ConfigurationError.
  def method_missing(sym, *args, &block)
    if @config.has_key?(sym)
      @config[sym]
    else
      raise(OpenRubyRMK::Errors::ConfigurationError, "Unknown directive/option '#{sym}'!")
    end
  end

end
