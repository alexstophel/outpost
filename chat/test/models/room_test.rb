require "test_helper"

class RoomTest < ActiveSupport::TestCase
  test "validates presence of name" do
    room = Room.new(name: nil, account: accounts(:one))

    assert_not room.valid?
    assert_includes room.errors[:name], "can't be blank"
  end

  test "belongs to account" do
    room = rooms(:general)

    assert_instance_of Account, room.account
    assert_equal accounts(:one), room.account
  end

  test "has many memberships" do
    room = rooms(:general)

    assert_respond_to room, :memberships
    assert room.memberships.count >= 1
  end

  test "has many users through memberships" do
    room = rooms(:general)

    assert_respond_to room, :users
    assert_includes room.users, users(:one)
  end

  test "has many messages" do
    room = rooms(:general)

    assert_respond_to room, :messages
    assert_includes room.messages, messages(:hello)
  end

  test "destroys memberships when destroyed" do
    room = rooms(:random)
    membership_count_before = Membership.count

    room.destroy

    assert_equal membership_count_before - 1, Membership.count
  end

  test "destroys messages when destroyed" do
    room = rooms(:general)
    room.messages.create!(body: "Test message", user: users(:one))
    message_count_before = room.messages.count

    room.destroy

    assert_equal 0, Message.where(room_id: room.id).count
  end
end
