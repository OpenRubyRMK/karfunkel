# -*- coding: utf-8 -*-
require "test/unit"
require "pathname"

require_relative "../lib/open_ruby_rmk/common"

class ResponseTest < Test::Unit::TestCase
  include OpenRubyRMK::Common

  #Responses need a request, so generate one.
  def setup
    @request = Request.new(3, "foo")
  end

  def test_reponse_creation
    resp = Response.new(33, "ok", @request)
    assert_equal(33, resp.id)
    assert_equal("ok", resp.status)
    assert_equal(@request, resp.request)
    resp = Response.new(43, :processing, @request)
    assert_equal("processing", resp.status)
  end

  def test_parameters
    resp = Response.new(2, "finished", @request)
    resp["foo"] = 33
    resp[:bar]  = "98"
    assert_equal(2, resp.parameters.count)
    assert_equal("33", resp[:foo])
    assert_equal("33", resp["foo"])
    assert_equal("98", resp[:bar])
    assert_equal("98", resp["bar"])
  end

  def test_equality
    resp1 = Response.new(1, "ok", @request)
    resp2 = Response.new(1, :ok, @request)
    resp3 = Response.new(2, "ok", nil)
    resp4 = Response.new(2, :ok, nil)
    resp5 = Response.new(1, "ok", Request.new(3, "bar"))

    assert_equal(resp1, resp2)
    assert_equal(resp2, resp1)
    assert_equal(resp3, resp4)
    assert_equal(resp4, resp3)
    assert_equal(resp1, resp1)
    assert_not_equal(resp1, resp3)
    assert_not_equal(resp3, resp1)
    assert_not_equal(resp1, resp4)
    assert_not_equal(resp4, resp1)
    assert_not_equal(resp4, resp5)
    assert_not_equal(resp5, resp4)
    assert_not_equal(resp1, resp5)
    assert_not_equal(resp5, resp1)
  end

  def test_mapping
    resp1 = Response.new(2, "ok", @request)
    resp2 = Response.new(3, "error", nil)
    assert(resp1.mapped?, "Response with request not considered mapped")
    assert(!resp2.mapped?, "Response without request considered mapped")
  end

end
