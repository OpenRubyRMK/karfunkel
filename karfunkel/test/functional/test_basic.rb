#-*- coding: utf-8 -*-
require_relative "../../lib/open_ruby_rmk/karfunkel/test_case"

OpenRubyRMK::Karfunkel::TestCase.new("Basic functionality") do

  at :startup do
    request :hello, :os => :linux, :version => OpenRubyRMK::Common::VERSION
  end

  test_response :hello do |res|
    id = res[:your_id].to_i
    assert_includes(1..Float::INFINITY, id)
    @client.id = id

    # Remember #request doesn’t wait for the response!
    request :invalidrequesttype
  end

  test_response :invalidrequesttype do |req|
    assert_equal("rejected", req.status)
    request :shutdown
  end

  test_request :shutdown do |req|
    response req, :ok
  end

  ########################################
  # General requests/responses unrelated
  # to the main comunication flow

  test_request :ping do |req|
    response req, :ok, :message => "pong"
  end

  test_response :ping do |res|
    # Nothing to do here
  end

end.run!
