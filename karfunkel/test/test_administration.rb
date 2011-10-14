require_relative "./karfunkel_test"

class AdministrationTest < KarfunkelTest

  def test_chat
    request "chat", :message => "I am a test message"
    assert_equal(@responses.first.type == "ChatMessage")
    assert_equal(@responses.first[:message] == "I am a test message")
  end

end
