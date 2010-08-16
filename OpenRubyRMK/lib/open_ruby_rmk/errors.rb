#!/usr/bin/env ruby
#Encoding: UTF-8

module OpenRubyRMK
  
  module Errors
    
    class OpenRubyRMKError < StandardError
    end
    
    class PluginError < OpenRubyRMKError
    end
    
    class InvalidMapsetError < OpenRubyRMKError
    end
    
  end
  
end