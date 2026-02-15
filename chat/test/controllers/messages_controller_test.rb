require "test_helper"

class MessagesControllerTest < ActionDispatch::IntegrationTest
  test "create requires authentication" do
    room = rooms(:general)

    post room_messages_path(room), params: { message: { body: "Hello" } }

    assert_redirected_to new_session_path
  end

  test "create adds message to room" do
    sign_in_as users(:one)
    room = rooms(:general)

    assert_difference "Message.count", 1 do
      post room_messages_path(room), params: { message: { body: "New message" } }
    end

    assert_redirected_to room_path(room)
    assert_equal "New message", Message.last.body
    assert_equal users(:one), Message.last.user
  end

  test "create with turbo stream format" do
    sign_in_as users(:one)
    room = rooms(:general)

    assert_difference "Message.count", 1 do
      post room_messages_path(room),
        params: { message: { body: "Turbo message" } },
        as: :turbo_stream
    end

    assert_response :success
  end

  test "create with invalid message renders form" do
    sign_in_as users(:one)
    room = rooms(:general)

    assert_no_difference "Message.count" do
      post room_messages_path(room), params: { message: { body: "" } }
    end

    assert_redirected_to room_path(room)
  end

  test "create only allows posting to rooms user is member of" do
    sign_in_as users(:one)
    other_account = Account.create!(name: "Other Account")
    other_room = other_account.rooms.create!(name: "Secret")

    post room_messages_path(other_room), params: { message: { body: "Hacking" } }

    assert_response :not_found
  end

  test "create does not allow posting to room user is not member of" do
    # user_two is not a member of random room
    sign_in_as users(:two)

    post room_messages_path(rooms(:random)), params: { message: { body: "Sneaky" } }

    assert_response :not_found
  end
end
