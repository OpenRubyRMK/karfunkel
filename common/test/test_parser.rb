require "test/unit"
require "pathname"

require_relative "../lib/open_ruby_rmk/common"

class ParserTest < Test::Unit::TestCase
  include OpenRubyRMK::Common

  DATA_DIR          = Pathname.new(__FILE__).dirname.expand_path + "data"

  def setup
    @transformer = Transformer.new
  end

  def test_normal_requests
    cmd = @transformer.parse!(xml("1.xml"))
    req = cmd.requests.first
    assert_equal(11, cmd.from_id)
    assert_equal(1, cmd.requests.count)
    assert_equal("foo", req.type)
    assert_equal(3, req.id)
    assert_equal("Parameter 1", req["par1"])
    assert_equal("Parameter 2", req["par2"])
    assert(req.running?, "Request was not running!")

    cmd = @transformer.parse!(xml("2.xml"))
    assert_equal(2, cmd.requests.count)
  end

  def test_hello_request
    cmd = @transformer.parse!(xml("hello1.xml"))
    assert_equal(-1, cmd.from_id)
    assert_equal(0, cmd.requests.first.id)

    assert_raises(Errors::MalformedCommand) do
      @transformer.parse!(xml("hello2.xml"))
    end
  end

  private

  def xml(name)
    DATA_DIR.join(name).read
  end

end
