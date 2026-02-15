require "test_helper"

class RoomReadTest < ActiveSupport::TestCase
  setup do
    @user = users(:one)
    @room = rooms(:general)
  end

  # Associations

  test "belongs to user" do
    room_read = RoomRead.new(user: @user, room: @room, last_read_at: Time.current)

    assert_equal @user, room_read.user
  end

  test "belongs to room" do
    room_read = RoomRead.new(user: @user, room: @room, last_read_at: Time.current)

    assert_equal @room, room_read.room
  end

  # Validations

  test "validates uniqueness of user_id scoped to room_id" do
    RoomRead.create!(user: @user, room: @room, last_read_at: Time.current)
    duplicate = RoomRead.new(user: @user, room: @room, last_read_at: Time.current)

    assert_not duplicate.valid?
    assert_includes duplicate.errors[:user_id], "has already been taken"
  end

  test "allows same user to have room_reads for different rooms" do
    RoomRead.create!(user: @user, room: @room, last_read_at: Time.current)
    other_room = rooms(:random)
    other_read = RoomRead.new(user: @user, room: other_room, last_read_at: Time.current)

    assert other_read.valid?
  end

  # unread?

  test "unread? returns true when messages exist after last_read_at" do
    room_read = RoomRead.create!(user: @user, room: @room, last_read_at: 1.hour.ago)
    @room.messages.create!(body: "New message", user: users(:two))

    assert room_read.unread?
  end

  test "unread? returns false when no messages after last_read_at" do
    @room.messages.update_all(created_at: 2.hours.ago)
    room_read = RoomRead.create!(user: @user, room: @room, last_read_at: 1.hour.ago)

    assert_not room_read.unread?
  end

  test "unread? returns false when room has no messages" do
    empty_room = Room.create!(name: "Empty", account: accounts(:one))
    room_read = RoomRead.create!(user: @user, room: empty_room, last_read_at: 1.hour.ago)

    assert_not room_read.unread?
  end

  # mark_read!

  test "mark_read! updates last_read_at to current time" do
    room_read = RoomRead.create!(user: @user, room: @room, last_read_at: 1.day.ago)

    room_read.mark_read!

    assert_in_delta Time.current, room_read.last_read_at, 1.second
  end

  test "mark_read! persists the change" do
    room_read = RoomRead.create!(user: @user, room: @room, last_read_at: 1.day.ago)

    room_read.mark_read!

    assert_in_delta Time.current, room_read.reload.last_read_at, 1.second
  end
end
