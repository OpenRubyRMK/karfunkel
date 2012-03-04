# -*- coding: utf-8 -*-

#This module contains any exceptions common to server and client
#libraries.
module OpenRubyRMK::Common::Errors

  # Superclass of every exception specific to the OpenRubyRMK.
  class OpenRubyRMKError < StandardError
  end

  # Raised if you fed invalid or logically wrong XML
  # to the Transformer.
  class MalformedCommand < OpenRubyRMKError
  end

  # Raised when authentication failed.
  class AuthenticationError < OpenRubyRMKError
  end

end
