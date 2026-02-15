require "test_helper"

class MessageTest < ActiveSupport::TestCase
  test "validates presence of body" do
    message = Message.new(body: nil, room: rooms(:general), user: users(:one))

    assert_not message.valid?
    assert_includes message.errors[:body], "can't be blank"
  end

  test "validates body cannot be blank string" do
    message = Message.new(body: "", room: rooms(:general), user: users(:one))

    assert_not message.valid?
    assert_includes message.errors[:body], "can't be blank"
  end

  test "belongs to room" do
    message = messages(:hello)

    assert_instance_of Room, message.room
    assert_equal rooms(:general), message.room
  end

  test "belongs to user" do
    message = messages(:hello)

    assert_instance_of User, message.user
    assert_equal users(:one), message.user
  end

  test "valid with body, room, and user" do
    message = Message.new(
      body: "Test message",
      room: rooms(:general),
      user: users(:one)
    )

    assert message.valid?
  end
end
