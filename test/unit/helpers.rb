# -*- coding: utf-8 -*-
require "test/unit"
require "tempfile"
require "turn/autorun"
require "zlib"
require "archive/tar/minitar"
require "tiled_tmx"

require_relative "../../lib/open_ruby_rmk/karfunkel"
require_relative "../../plugins/base/invalidatable"
require_relative "../../plugins/base/category"
require_relative "../../plugins/base/project"
require_relative "../../plugins/base/map"

# Ignore any calls to the server. This is a unit test, and
# doesn’t need the server. Merely this is used to ignore
# calls to the server’s logger which isn’t set up as
# Karfunkel isn’t running.
class OpenRubyRMK::Karfunkel
  THE_INSTANCE = Object.new
  THE_INSTANCE.instance_eval do
    def method_missing(*) # :nodoc:
      self
    end
  end
end
