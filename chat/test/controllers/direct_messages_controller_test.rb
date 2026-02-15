require "test_helper"

class DirectMessagesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    @other_user = users(:two)
  end

  test "create creates a new DM room between users" do
    sign_in_as @user

    assert_difference "Room.count", 1 do
      post direct_messages_path, params: { user_id: @other_user.id }
    end

    dm_room = Room.last
    assert dm_room.direct_message?
    assert_includes dm_room.users, @user
    assert_includes dm_room.users, @other_user
    assert_redirected_to room_path(dm_room)
  end

  test "create returns existing DM if one exists" do
    sign_in_as @user
    existing_dm = Room.find_or_create_dm(@user, @other_user, @user.account)

    assert_no_difference "Room.count" do
      post direct_messages_path, params: { user_id: @other_user.id }
    end

    assert_redirected_to room_path(existing_dm)
  end

  test "create returns 404 for user not in same account" do
    sign_in_as @user
    other_account = Account.create!(name: "Other Account")
    external_user = other_account.users.create!(
      name: "External User",
      email_address: "external@example.com",
      password: "password123"
    )

    post direct_messages_path, params: { user_id: external_user.id }

    assert_response :not_found
  end

  test "create returns 404 for non-existent user" do
    sign_in_as @user

    post direct_messages_path, params: { user_id: 999999 }

    assert_response :not_found
  end

  test "create requires authentication" do
    post direct_messages_path, params: { user_id: @other_user.id }

    assert_redirected_to new_session_path
  end
end
