require "test_helper"

class MessageBroadcastTest < ActiveSupport::TestCase
  test "deliver broadcasts message to room without raising" do
    message = messages(:hello)
    broadcast = MessageBroadcast.new(message)

    # Verify it completes without raising
    assert_nothing_raised do
      broadcast.deliver
    end
  end

  test "preloads user with avatar attachment" do
    message = messages(:hello)
    broadcast = MessageBroadcast.new(message)

    # Access private method for testing preload behavior
    preloaded = broadcast.send(:preloaded_message)

    assert_equal message.id, preloaded.id
    assert preloaded.user.present?
  end
end
