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

  # Room type helpers

  test "default_room? returns true for General room" do
    room = rooms(:general)

    assert room.default_room?
  end

  test "default_room? returns false for other rooms" do
    room = rooms(:random)

    assert_not room.default_room?
  end

  test "default_room? is case insensitive" do
    room = Room.new(name: "GENERAL", account: accounts(:one))

    assert room.default_room?
  end

  test "deletable? returns false for General room" do
    room = rooms(:general)

    assert_not room.deletable?
  end

  test "deletable? returns true for other rooms" do
    room = rooms(:random)

    assert room.deletable?
  end

  test "membership_editable? returns false for General room" do
    room = rooms(:general)

    assert_not room.membership_editable?
  end

  test "membership_editable? returns true for other rooms" do
    room = rooms(:random)

    assert room.membership_editable?
  end

  # Display name

  test "display_name_for returns room name for channels" do
    room = rooms(:general)

    assert_equal "General", room.display_name_for(users(:one))
  end

  test "display_name_for returns other user name for DMs" do
    user_a = users(:one)
    user_b = users(:two)
    dm = Room.find_or_create_dm(user_a, user_b, accounts(:one))

    assert_equal user_b.name, dm.display_name_for(user_a)
    assert_equal user_a.name, dm.display_name_for(user_b)
  end

  # Other participant

  test "other_participant returns nil for channels" do
    room = rooms(:general)

    assert_nil room.other_participant(users(:one))
  end

  test "other_participant returns other user for DMs" do
    user_a = users(:one)
    user_b = users(:two)
    dm = Room.find_or_create_dm(user_a, user_b, accounts(:one))

    assert_equal user_b, dm.other_participant(user_a)
    assert_equal user_a, dm.other_participant(user_b)
  end

  # Last message at

  test "last_message_at returns most recent message timestamp" do
    room = rooms(:general)
    recent_message = room.messages.create!(body: "Recent", user: users(:one))

    assert_equal recent_message.created_at, room.last_message_at
  end

  test "last_message_at returns room created_at when no messages" do
    room = Room.create!(name: "Empty", account: accounts(:one))

    assert_equal room.created_at, room.last_message_at
  end

  # Find or create DM

  test "find_or_create_dm creates new DM between users" do
    user_a = users(:one)
    user_b = users(:two)

    dm = nil
    assert_difference "Room.count", 1 do
      dm = Room.find_or_create_dm(user_a, user_b, accounts(:one))
    end

    assert dm.direct_message?
    assert_includes dm.users, user_a
    assert_includes dm.users, user_b
  end

  test "find_or_create_dm returns existing DM" do
    user_a = users(:one)
    user_b = users(:two)
    existing_dm = Room.find_or_create_dm(user_a, user_b, accounts(:one))

    assert_no_difference "Room.count" do
      found_dm = Room.find_or_create_dm(user_a, user_b, accounts(:one))
      assert_equal existing_dm, found_dm
    end
  end

  test "find_or_create_dm returns same DM regardless of user order" do
    user_a = users(:one)
    user_b = users(:two)
    dm1 = Room.find_or_create_dm(user_a, user_b, accounts(:one))
    dm2 = Room.find_or_create_dm(user_b, user_a, accounts(:one))

    assert_equal dm1, dm2
  end

  # Scopes

  test "channels scope returns only channel rooms" do
    Room.find_or_create_dm(users(:one), users(:two), accounts(:one))

    channels = Room.channels

    assert channels.all?(&:channel?)
  end

  test "direct_messages scope returns only DM rooms" do
    Room.find_or_create_dm(users(:one), users(:two), accounts(:one))

    dms = Room.direct_messages

    assert dms.all?(&:direct_message?)
  end

  test "joinable_by returns public rooms user is not a member of" do
    user = users(:two)
    public_room = Room.create!(name: "Public", account: accounts(:one), visibility: "public")

    joinable = Room.joinable_by(user)

    assert_includes joinable, public_room
    assert_not_includes joinable, rooms(:general) # user is already a member
  end

  test "joinable_by excludes private rooms" do
    user = users(:two)
    private_room = Room.create!(name: "Private", account: accounts(:one), visibility: "private")

    joinable = Room.joinable_by(user)

    assert_not_includes joinable, private_room
  end

  # unread? method

  test "unread? returns false when has_unread attribute not present" do
    room = rooms(:general)

    assert_not room.unread?
  end

  test "unread? returns true when has_unread is 1" do
    user = users(:one)
    dm = Room.find_or_create_dm(user, users(:two), accounts(:one))
    dm.messages.create!(body: "Hello", user: users(:two))

    dms = user.direct_message_rooms_with_unread_status
    dm_with_status = dms.find { |r| r.id == dm.id }

    assert dm_with_status.unread?
  end

  test "unread? returns false when has_unread is 0" do
    user = users(:one)
    dm = Room.find_or_create_dm(user, users(:two), accounts(:one))
    dm.messages.create!(body: "Hello", user: users(:two), created_at: 1.hour.ago)
    user.mark_room_as_read!(dm)

    dms = user.direct_message_rooms_with_unread_status
    dm_with_status = dms.find { |r| r.id == dm.id }

    assert_not dm_with_status.unread?
  end

  # has_messages_since?

  test "has_messages_since? returns true when messages exist after timestamp" do
    room = rooms(:general)
    room.messages.create!(body: "New message", user: users(:one))

    assert room.has_messages_since?(1.hour.ago)
  end

  test "has_messages_since? returns false when no messages after timestamp" do
    room = rooms(:general)
    room.messages.update_all(created_at: 2.hours.ago)

    assert_not room.has_messages_since?(1.hour.ago)
  end

  test "has_messages_since? returns false when no messages" do
    room = Room.create!(name: "Empty", account: accounts(:one))

    assert_not room.has_messages_since?(1.hour.ago)
  end
end
