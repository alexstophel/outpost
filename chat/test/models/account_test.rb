require "test_helper"

class AccountTest < ActiveSupport::TestCase
  test "setup? returns false when no accounts exist" do
    # Delete in correct order to respect foreign keys
    Message.delete_all
    Membership.delete_all
    Room.delete_all
    Session.delete_all
    User.delete_all
    Account.delete_all

    result = Account.setup?

    assert_not result
  end

  test "setup? returns true when an account exists" do
    result = Account.setup?

    assert result
  end

  test "validates presence of name" do
    account = Account.new(name: nil)

    assert_not account.valid?
    assert_includes account.errors[:name], "can't be blank"
  end

  test "generates invite_token on create" do
    # Delete in correct order to respect foreign keys
    Message.delete_all
    Membership.delete_all
    Room.delete_all
    Session.delete_all
    User.delete_all
    Account.delete_all

    account = Account.create!(name: "New Account")

    assert_not_nil account.invite_token
    assert_equal 16, account.invite_token.length
  end

  test "regenerate_invite_token! changes the token" do
    account = accounts(:one)
    old_token = account.invite_token

    account.regenerate_invite_token!

    assert_not_equal old_token, account.invite_token
  end

  test "invite_url returns full URL with token" do
    account = accounts(:one)

    url = account.invite_url(host: "https://example.com")

    assert_equal "https://example.com/join/#{account.invite_token}", url
  end
end
