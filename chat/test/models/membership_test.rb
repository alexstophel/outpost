require "test_helper"

class MembershipTest < ActiveSupport::TestCase
  test "validates uniqueness of user per room" do
    existing = memberships(:user_one_general)
    duplicate = Membership.new(room: existing.room, user: existing.user)

    assert_not duplicate.valid?
    assert_includes duplicate.errors[:user_id], "has already been taken"
  end

  test "belongs to room" do
    membership = memberships(:user_one_general)

    assert_instance_of Room, membership.room
    assert_equal rooms(:general), membership.room
  end

  test "belongs to user" do
    membership = memberships(:user_one_general)

    assert_instance_of User, membership.user
    assert_equal users(:one), membership.user
  end

  test "allows same user in different rooms" do
    user = users(:one)
    new_room = Room.create!(name: "New Room", account: accounts(:one))
    membership = Membership.new(room: new_room, user: user)

    assert membership.valid?
  end

  test "allows different users in same room" do
    room = rooms(:general)
    new_user = User.create!(
      name: "New User",
      email_address: "new@example.com",
      password: "password123",
      account: accounts(:one)
    )
    membership = Membership.new(room: room, user: new_user)

    assert membership.valid?
  end
end
