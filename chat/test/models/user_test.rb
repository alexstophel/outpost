require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "downcases and strips email_address" do
    user = User.new(email_address: " DOWNCASED@EXAMPLE.COM ")

    assert_equal "downcased@example.com", user.email_address
  end

  test "validates presence of email_address" do
    user = User.new(
      email_address: nil,
      password: "password123",
      account: accounts(:one)
    )

    assert_not user.valid?
    assert_includes user.errors[:email_address], "can't be blank"
  end

  test "validates uniqueness of email_address" do
    existing_user = users(:one)
    user = User.new(
      email_address: existing_user.email_address,
      password: "password123",
      account: accounts(:one)
    )

    assert_not user.valid?
    assert_includes user.errors[:email_address], "has already been taken"
  end

  test "validates presence of password on create" do
    user = User.new(
      email_address: "new@example.com",
      password: "",
      account: accounts(:one)
    )

    assert_not user.valid?
    assert_includes user.errors[:password], "can't be blank"
  end

  test "validates password minimum length" do
    user = User.new(
      name: "Test User",
      email_address: "new@example.com",
      password: "short",
      account: accounts(:one)
    )

    assert_not user.valid?
    assert_includes user.errors[:password], "is too short (minimum is 8 characters)"
  end

  test "accepts password with 8 or more characters" do
    user = User.new(
      name: "Test User",
      email_address: "new@example.com",
      password: "password123",
      account: accounts(:one)
    )

    assert user.valid?
  end

  test "belongs to account" do
    user = users(:one)

    assert_instance_of Account, user.account
    assert_equal accounts(:one), user.account
  end

  test "has many sessions" do
    user = users(:one)
    initial_count = user.sessions.count
    user.sessions.create!

    assert_equal initial_count + 1, user.sessions.count
  end

  test "destroys sessions when destroyed" do
    user = users(:one)
    user.sessions.create!
    user_session_count = user.sessions.count

    user.destroy

    assert_equal 0, Session.where(user_id: user.id).count
  end

  # Lockout methods

  test "locked? returns false when locked_at is nil" do
    user = users(:one)
    user.locked_at = nil

    assert_not user.locked?
  end

  test "locked? returns false when locked_at is older than lockout duration" do
    user = users(:one)
    user.locked_at = 31.minutes.ago

    assert_not user.locked?
  end

  test "locked? returns true when locked_at is within lockout duration" do
    user = users(:one)
    user.locked_at = 10.minutes.ago

    assert user.locked?
  end

  test "lock_access! sets locked_at and failed_login_attempts" do
    user = users(:one)

    user.lock_access!

    assert_not_nil user.locked_at
    assert_equal User::MAX_FAILED_ATTEMPTS, user.failed_login_attempts
  end

  test "unlock_access! clears locked_at and failed_login_attempts" do
    user = users(:one)
    user.update!(locked_at: Time.current, failed_login_attempts: 5)

    user.unlock_access!

    assert_nil user.locked_at
    assert_equal 0, user.failed_login_attempts
  end

  test "record_failed_login! increments failed_login_attempts" do
    user = users(:one)
    user.update!(failed_login_attempts: 0)

    user.record_failed_login!

    assert_equal 1, user.failed_login_attempts
  end

  test "record_failed_login! locks account after max attempts" do
    user = users(:one)
    user.update!(failed_login_attempts: User::MAX_FAILED_ATTEMPTS - 1)

    user.record_failed_login!

    assert user.locked?
  end

  test "record_successful_login! resets failed attempts" do
    user = users(:one)
    user.update!(failed_login_attempts: 3, locked_at: 1.hour.ago)

    user.record_successful_login!

    assert_equal 0, user.failed_login_attempts
    assert_nil user.locked_at
  end

  test "record_successful_login! does nothing when no failed attempts" do
    user = users(:one)
    user.update!(failed_login_attempts: 0, locked_at: nil)
    updated_at_before = user.updated_at

    user.record_successful_login!

    assert_equal updated_at_before, user.reload.updated_at
  end

  # Room membership methods

  test "admin_of? returns true when user is admin of room" do
    user = users(:one)
    room = Room.create!(name: "Test", account: accounts(:one))
    room.memberships.create!(user: user, role: :admin)

    assert user.admin_of?(room)
  end

  test "admin_of? returns false when user is not admin of room" do
    user = users(:one)
    room = Room.create!(name: "Test", account: accounts(:one))
    room.memberships.create!(user: user, role: :member)

    assert_not user.admin_of?(room)
  end

  test "admin_of? returns false when user is not a member" do
    user = users(:one)
    room = Room.create!(name: "Test", account: accounts(:one))

    assert_not user.admin_of?(room)
  end

  test "member_of? returns true when user is a member" do
    user = users(:one)
    room = rooms(:general)

    assert user.member_of?(room)
  end

  test "member_of? returns false when user is not a member" do
    user = users(:two)
    room = rooms(:random)

    assert_not user.member_of?(room)
  end

  test "membership_for returns the membership for a room" do
    user = users(:one)
    room = rooms(:general)

    membership = user.membership_for(room)

    assert_instance_of Membership, membership
    assert_equal user, membership.user
    assert_equal room, membership.room
  end

  test "membership_for returns nil when not a member" do
    user = users(:two)
    room = rooms(:random)

    assert_nil user.membership_for(room)
  end

  # Unread methods

  test "has_unread_in? returns true when room has never been read" do
    user = users(:one)
    room = rooms(:general)
    user.room_reads.where(room: room).delete_all

    assert user.has_unread_in?(room)
  end

  test "has_unread_in? returns true when new messages exist" do
    user = users(:one)
    room = rooms(:general)
    room_read = user.room_reads.find_or_initialize_by(room: room)
    room_read.last_read_at = 1.hour.ago
    room_read.save!
    room.messages.create!(body: "New message", user: users(:two))

    assert user.has_unread_in?(room)
  end

  test "has_unread_in? returns false when no new messages" do
    user = users(:one)
    room = rooms(:general)
    room_read = user.room_reads.find_or_initialize_by(room: room)
    room_read.last_read_at = Time.current
    room_read.save!

    assert_not user.has_unread_in?(room)
  end

  test "mark_room_as_read! creates room_read if not exists" do
    user = users(:one)
    room = rooms(:general)
    user.room_reads.where(room: room).delete_all

    assert_difference "RoomRead.count", 1 do
      user.mark_room_as_read!(room)
    end
  end

  test "mark_room_as_read! updates existing room_read" do
    user = users(:one)
    room = rooms(:general)
    room_read = user.room_reads.find_or_initialize_by(room: room)
    room_read.last_read_at = 1.day.ago
    room_read.save!

    user.mark_room_as_read!(room)

    assert_in_delta Time.current, room_read.reload.last_read_at, 1.second
  end

  # Account peers

  test "account_peers returns other users in same account" do
    user = users(:one)

    peers = user.account_peers

    assert_includes peers, users(:two)
    assert_not_includes peers, user
  end

  # Optimized DM rooms with unread status

  test "direct_message_rooms_with_unread_status returns DMs with has_unread attribute" do
    user_a = users(:one)
    user_b = users(:two)
    dm = Room.find_or_create_dm(user_a, user_b, accounts(:one))
    dm.messages.create!(body: "Hello", user: user_b)

    dms = user_a.direct_message_rooms_with_unread_status

    assert_includes dms, dm
    assert_respond_to dms.first, :has_unread
  end

  test "direct_message_rooms_with_unread_status marks unread when never read" do
    user_a = users(:one)
    user_b = users(:two)
    dm = Room.find_or_create_dm(user_a, user_b, accounts(:one))
    dm.messages.create!(body: "Hello", user: user_b)
    user_a.room_reads.where(room: dm).delete_all

    dms = user_a.direct_message_rooms_with_unread_status
    dm_result = dms.find { |r| r.id == dm.id }

    assert_equal 1, dm_result.has_unread
  end

  test "direct_message_rooms_with_unread_status marks read when no new messages" do
    user_a = users(:one)
    user_b = users(:two)
    dm = Room.find_or_create_dm(user_a, user_b, accounts(:one))
    dm.messages.create!(body: "Hello", user: user_b, created_at: 1.hour.ago)
    user_a.mark_room_as_read!(dm)

    dms = user_a.direct_message_rooms_with_unread_status
    dm_result = dms.find { |r| r.id == dm.id }

    assert_equal 0, dm_result.has_unread
  end

  test "direct_message_rooms_with_unread_status marks unread when new message after read" do
    user_a = users(:one)
    user_b = users(:two)
    dm = Room.find_or_create_dm(user_a, user_b, accounts(:one))
    user_a.mark_room_as_read!(dm)
    dm.messages.create!(body: "New message", user: user_b)

    dms = user_a.direct_message_rooms_with_unread_status
    dm_result = dms.find { |r| r.id == dm.id }

    assert_equal 1, dm_result.has_unread
  end
end
