require "test_helper"

class AccountSetupTest < ActiveSupport::TestCase
  setup do
    # Clear existing data to test fresh setup
    Membership.delete_all
    Message.delete_all
    Room.delete_all
    Session.delete_all
    User.delete_all
    Account.delete_all
  end

  test "validates presence of account_name" do
    setup = AccountSetup.new(
      account_name: "",
      user_name: "Admin",
      email_address: "admin@example.com",
      password: "password123",
      password_confirmation: "password123"
    )

    assert_not setup.valid?
    assert_includes setup.errors[:account_name], "can't be blank"
  end

  test "validates presence of user_name" do
    setup = AccountSetup.new(
      account_name: "My Team",
      user_name: "",
      email_address: "admin@example.com",
      password: "password123",
      password_confirmation: "password123"
    )

    assert_not setup.valid?
    assert_includes setup.errors[:user_name], "can't be blank"
  end

  test "validates presence of email_address" do
    setup = AccountSetup.new(
      account_name: "My Team",
      user_name: "Admin",
      email_address: "",
      password: "password123",
      password_confirmation: "password123"
    )

    assert_not setup.valid?
    assert_includes setup.errors[:email_address], "can't be blank"
  end

  test "validates presence of password" do
    setup = AccountSetup.new(
      account_name: "My Team",
      user_name: "Admin",
      email_address: "admin@example.com",
      password: "",
      password_confirmation: ""
    )

    assert_not setup.valid?
    assert_includes setup.errors[:password], "can't be blank"
  end

  test "validates password confirmation matches" do
    setup = AccountSetup.new(
      account_name: "My Team",
      user_name: "Admin",
      email_address: "admin@example.com",
      password: "password123",
      password_confirmation: "different"
    )

    assert_not setup.valid?
    assert_includes setup.errors[:password_confirmation], "doesn't match Password"
  end

  test "save creates account, user, room, and membership" do
    setup = AccountSetup.new(
      account_name: "My Team",
      user_name: "Admin User",
      email_address: "admin@example.com",
      password: "password123",
      password_confirmation: "password123"
    )

    assert_difference [ "Account.count", "User.count", "Room.count", "Membership.count" ], 1 do
      assert setup.save
    end

    assert_equal "My Team", setup.account.name
    assert_equal "Admin User", setup.user.name
    assert_equal "admin@example.com", setup.user.email_address
    assert setup.user.admin?
    assert_equal "General", setup.account.rooms.first.name
    assert_includes setup.user.rooms, setup.account.rooms.first
  end

  test "save returns false with invalid data" do
    setup = AccountSetup.new(
      account_name: "",
      user_name: "Admin",
      email_address: "admin@example.com",
      password: "password123",
      password_confirmation: "password123"
    )

    assert_no_difference [ "Account.count", "User.count" ] do
      assert_not setup.save
    end
  end

  test "save rolls back on user validation failure" do
    setup = AccountSetup.new(
      account_name: "My Team",
      user_name: "", # User name is required
      email_address: "admin@example.com",
      password: "password123",
      password_confirmation: "password123"
    )

    assert_no_difference [ "Account.count", "User.count" ] do
      assert_not setup.save
    end
  end
end
