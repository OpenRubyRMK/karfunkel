# -*- coding: utf-8 -*-
require "test/unit"
require "pathname"

require_relative "../lib/open_ruby_rmk/common"

class RequestTest < Test::Unit::TestCase
  include OpenRubyRMK::Common

  def test_request_creation
    req = Request.new(2, "foo")
    assert_equal(2, req.id)
    assert_equal("foo", req.type)
    req = Request.new(2, :foo)
    assert_equal("foo", req.type)
  end

  def test_parameters
    req = Request.new(2, "foo")
    req["foo"] = 33
    req[:bar]  = "98"
    assert_equal(2, req.parameters.count)
    assert_equal("33", req[:foo])
    assert_equal("33", req["foo"])
    assert_equal("98", req[:bar])
    assert_equal("98", req["bar"])
  end

  def test_equality
    req1 = Request.new(2, "foo")
    req2 = Request.new(2, :foo)
    req3 = Request.new(3, "foo")

    assert_equal(req1, req2)
    assert_equal(req2, req1)
    assert_equal(req1, req1)
    assert_not_equal(req1, req3)
    assert_not_equal(req3, req1)
  end

  def test_running
    req = Request.new(2, "foo")
    assert(req.running?, "Newly created request not running")
    req.responses << Response.new(45, "processing", req)
    assert(req.running?, "Processing request not running")
    req.responses << Response.new(55, "finished", req)
    assert(!req.running?, "Finished request still running")

    req = Request.new(2, "foo")
    req.responses << Response.new(2, :ok, req)
    assert(!req.running?, "OKed request still running")
  end

end
