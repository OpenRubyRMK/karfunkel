# -*- coding: utf-8 -*-
require_relative "../lib/open_ruby_rmk/karfunkel/test_case"

OpenRubyRMK::Karfunkel::TestCase.new("Unauthenticated things") do

  at :startup do
    request :shutdown
  end

  test_response :shutdown do |res|
      assert_equal("rejected", req.status)
      request :hello, :os => :linux, :version => OpenRubyRMK::Common::VERSION
  end

  test_response :hello do |res|
    @client.id = res[:your_id].to_i
    request :shutdown
  end

  test_request :shutdown do |req|
    response req, :ok
  end

end.run!
