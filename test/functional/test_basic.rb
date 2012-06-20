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

  test_response :invalidrequesttype do |res|
    assert_equal("rejected", res.status)
    request :shutdown
  end

  test_request :shutdown do |req|
    assert_equal(1, req["requestor"].to_i) # It was us who sent the request originally
    response req, :ok
  end

  test_response :shutdown do |res|
    assert_equal("ok", res.status)
    request :ping
  end

  test_response :ping do |res|
    assert_equal "ok", res.status
    # Nothing to do here
  end

end.run!
