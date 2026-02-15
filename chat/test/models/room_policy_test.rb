require "test_helper"

class RoomPolicyTest < ActiveSupport::TestCase
  setup do
    @user = users(:one)
    @other_user = users(:two)
    @account = accounts(:one)
  end

  # admin?

  test "admin? returns true when user is admin of room" do
    room = Room.create!(name: "Test", account: @account)
    room.memberships.create!(user: @user, role: :admin)
    policy = RoomPolicy.new(@user, room)

    assert policy.admin?
  end

  test "admin? returns false when user is not admin" do
    room = Room.create!(name: "Test", account: @account)
    room.memberships.create!(user: @user, role: :member)
    policy = RoomPolicy.new(@user, room)

    assert_not policy.admin?
  end

  # member?

  test "member? returns true when user is member" do
    room = rooms(:general)
    policy = RoomPolicy.new(@user, room)

    assert policy.member?
  end

  test "member? returns false when user is not member" do
    room = rooms(:random)
    policy = RoomPolicy.new(@other_user, room)

    assert_not policy.member?
  end

  # can_join?

  test "can_join? returns true for public room user is not member of" do
    room = Room.create!(name: "Public", account: @account, visibility: "public")
    policy = RoomPolicy.new(@user, room)

    assert policy.can_join?
  end

  test "can_join? returns false for private room" do
    room = Room.create!(name: "Private", account: @account, visibility: "private")
    policy = RoomPolicy.new(@user, room)

    assert_not policy.can_join?
  end

  test "can_join? returns false when already a member" do
    room = rooms(:general)
    policy = RoomPolicy.new(@user, room)

    assert_not policy.can_join?
  end

  # can_add_member?

  test "can_add_member? returns true for public room" do
    room = Room.create!(name: "Public", account: @account, visibility: "public")
    policy = RoomPolicy.new(@user, room)

    assert policy.can_add_member?
  end

  test "can_add_member? returns true for admin of private room" do
    room = Room.create!(name: "Private", account: @account, visibility: "private")
    room.memberships.create!(user: @user, role: :admin)
    policy = RoomPolicy.new(@user, room)

    assert policy.can_add_member?
  end

  test "can_add_member? returns false for non-admin of private room" do
    room = Room.create!(name: "Private", account: @account, visibility: "private")
    room.memberships.create!(user: @user, role: :member)
    policy = RoomPolicy.new(@user, room)

    assert_not policy.can_add_member?
  end

  # can_remove_member?

  test "can_remove_member? returns true for admin removing other member" do
    room = Room.create!(name: "Test", account: @account)
    room.memberships.create!(user: @user, role: :admin)
    other_membership = room.memberships.create!(user: @other_user, role: :member)
    policy = RoomPolicy.new(@user, room)

    assert policy.can_remove_member?(other_membership)
  end

  test "can_remove_member? returns false for non-admin" do
    room = Room.create!(name: "Test", account: @account)
    room.memberships.create!(user: @user, role: :member)
    other_membership = room.memberships.create!(user: @other_user, role: :member)
    policy = RoomPolicy.new(@user, room)

    assert_not policy.can_remove_member?(other_membership)
  end

  test "can_remove_member? returns false when removing self" do
    room = Room.create!(name: "Test", account: @account)
    membership = room.memberships.create!(user: @user, role: :admin)
    policy = RoomPolicy.new(@user, room)

    assert_not policy.can_remove_member?(membership)
  end

  # can_leave?

  test "can_leave? returns true for member" do
    room = Room.create!(name: "Test", account: @account)
    room.memberships.create!(user: @user, role: :member)
    policy = RoomPolicy.new(@user, room)

    assert policy.can_leave?
  end

  test "can_leave? returns false for only admin" do
    room = Room.create!(name: "Test", account: @account)
    room.memberships.create!(user: @user, role: :admin)
    policy = RoomPolicy.new(@user, room)

    assert_not policy.can_leave?
  end

  test "can_leave? returns true for admin when another admin exists" do
    room = Room.create!(name: "Test", account: @account)
    room.memberships.create!(user: @user, role: :admin)
    room.memberships.create!(user: @other_user, role: :admin)
    policy = RoomPolicy.new(@user, room)

    assert policy.can_leave?
  end

  test "can_leave? returns false for General room" do
    room = rooms(:general)
    policy = RoomPolicy.new(@user, room)

    assert_not policy.can_leave?
  end

  # can_edit_membership?

  test "can_edit_membership? returns true for non-General room" do
    room = rooms(:random)
    policy = RoomPolicy.new(@user, room)

    assert policy.can_edit_membership?
  end

  test "can_edit_membership? returns false for General room" do
    room = rooms(:general)
    policy = RoomPolicy.new(@user, room)

    assert_not policy.can_edit_membership?
  end

  # can_delete?

  test "can_delete? returns true for admin of deletable room" do
    room = Room.create!(name: "Test", account: @account)
    room.memberships.create!(user: @user, role: :admin)
    policy = RoomPolicy.new(@user, room)

    assert policy.can_delete?
  end

  test "can_delete? returns false for non-admin" do
    room = Room.create!(name: "Test", account: @account)
    room.memberships.create!(user: @user, role: :member)
    policy = RoomPolicy.new(@user, room)

    assert_not policy.can_delete?
  end

  test "can_delete? returns false for General room" do
    room = rooms(:general)
    room.memberships.find_by(user: @user)&.update!(role: :admin)
    policy = RoomPolicy.new(@user, room)

    assert_not policy.can_delete?
  end

  # can_view_settings?

  test "can_view_settings? returns true for member of channel" do
    room = rooms(:general)
    policy = RoomPolicy.new(@user, room)

    assert policy.can_view_settings?
  end

  test "can_view_settings? returns false for non-member" do
    room = rooms(:random)
    policy = RoomPolicy.new(@other_user, room)

    assert_not policy.can_view_settings?
  end

  test "can_view_settings? returns false for DM" do
    dm = Room.find_or_create_dm(@user, @other_user, @account)
    policy = RoomPolicy.new(@user, dm)

    assert_not policy.can_view_settings?
  end
end
