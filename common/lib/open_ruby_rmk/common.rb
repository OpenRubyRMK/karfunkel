require "pathname"
require "nokogiri"

#This module encapsulates all classes that are relevant to
#both the server and the client.
module OpenRubyRMK::Common

  VERSION = Pathname.new(__FILE__).dirname.parent.parent.join("VERSION").read

end

require_relative "common/errors"
require_relative "common/transformer"
require_relative "common/command"
require_relative "common/request"
require_relative "common/response"
require_relative "common/notification"

