# -*- coding: utf-8 -*-
require_relative "../lib/open_ruby_rmk/karfunkel/test_case"

OpenRubyRMK::Karfunkel::TestCase.new("Project management") do

  @testproject = Pathname.new("/tmp/testproject")

  at :startup do
    request :hello, :os => :linux, :version => OpenRubyRMK::Common::VERSION
    @existing_project = false
    @invalid_project  = false
  end

  test_response :hello do |res|
    @client.id = res[:your_id].to_i
    request :new_project, :path => @testproject
  end

  test_response :new_project do |res|
    unless @existing_project
      assert_equal("ok", res.status)
      assert_includes(0..Float::INFINITY, res.id.to_i)
      assert(File.directory?(@testproject), "Test directory not created")
      assert(File.file?(@testproject + "bin" + "#{@testproject.basename}.rmk"), "#{@testproject.basename}.rmk not created")
      request :close_project, :id => res[:id]
    else
      assert_equal("rejected", res.status)
      request :shutdown # End of test
    end
  end

  test_response :close_project do |res|
    assert_equal("ok", res.status)
    request :open_project, :path => @testproject
  end

  test_response :open_project do |res|
    unless @invalid_project
      assert_equal("ok", res.status)
      assert_includes(0..Float::INFINITY, res.id.to_i)
      request :delete_project, :id => res[:id]
    else
      assert_equal("rejected", res.status)
      @existing_project = true
      request :new_project, :path => "/tmp"
    end
  end

  test_response :delete_project do |res|
    assert_equal("ok", res.status)
    refute(File.directory?(@testproject), "Did not delete #{@testproject} directory")
    @invalid_project = true
    request :open_project, :path => "/nonexistant"
  end

  test_request :shutdown do |req|
    response req, :ok
  end

  test_request :ping do |req|
    response req, :ok, :message => "pong"
  end

end.run!
