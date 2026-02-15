require "test_helper"

class RoomsControllerTest < ActionDispatch::IntegrationTest
  test "show requires authentication" do
    room = rooms(:general)

    get room_path(room)

    assert_redirected_to new_session_path
  end

  test "show renders room for authenticated member" do
    sign_in_as users(:one)
    room = rooms(:general)

    get room_path(room)

    assert_response :success
  end

  test "show displays room name" do
    sign_in_as users(:one)
    room = rooms(:general)

    get room_path(room)

    assert_select "h2", text: /general/i
  end

  test "show displays messages" do
    sign_in_as users(:one)
    room = rooms(:general)

    get room_path(room)

    assert_select "#messages"
  end

  test "show only allows access to rooms user is member of" do
    sign_in_as users(:one)
    other_account = Account.create!(name: "Other Account")
    other_room = other_account.rooms.create!(name: "Secret")

    get room_path(other_room)

    assert_response :not_found
  end

  test "show does not allow access to room user is not member of" do
    # user_two is not a member of random room
    sign_in_as users(:two)

    get room_path(rooms(:random))

    assert_response :not_found
  end
end
