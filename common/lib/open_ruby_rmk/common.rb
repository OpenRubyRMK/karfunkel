# -*- coding: utf-8 -*-

require "pathname"
require "nokogiri"

#The OpenRubyRMK’s namespace.
module OpenRubyRMK

  #This module encapsulates all classes that are relevant to
  #both the server and the client.
  module Common
    
    #The version number of this library, something of form <tt>MAYOR.MINOR.TINY</tt>.
    VERSION = Pathname.new(__FILE__).dirname.parent.parent.join("VERSION").read

  end

end

require_relative "common/errors"
require_relative "common/transformer"
require_relative "common/command"
require_relative "common/request"
require_relative "common/response"
require_relative "common/notification"

