#-*- coding: utf-8 -*-
require_relative "../lib/open_ruby_rmk/karfunkel/test_case"

OpenRubyRMK::Karfunkel::TestCase.new("Basic functionality") do

  at :startup do
    request :hello, :os => :linux, :version => OpenRubyRMK::Common::VERSION
  end

  test_response :hello do |res|
    id = res[:your_id].to_i
    assert_includes(1..Float::INFINITY, id)
    @client.id = id
  end

  test_request :ping do |req|
    response req, :ok
  end

  test_request :shutdown do |req|
    response req, :ok
  end

end
