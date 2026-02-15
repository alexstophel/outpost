require "test_helper"

class HomeControllerTest < ActionDispatch::IntegrationTest
  test "redirects to setup when no account exists" do
    # Delete in correct order to respect foreign keys
    Message.delete_all
    Membership.delete_all
    Room.delete_all
    Session.delete_all
    User.delete_all
    Account.delete_all

    get root_path

    assert_redirected_to new_setup_path
  end

  test "redirects to sign in when not authenticated" do
    get root_path

    assert_redirected_to new_session_path
  end

  test "redirects authenticated user to first room" do
    sign_in_as users(:one)

    get root_path

    assert_redirected_to room_path(rooms(:general))
  end

  test "shows home page when user has no rooms" do
    user = users(:one)
    user.memberships.delete_all
    sign_in_as user

    get root_path

    assert_response :success
  end
end
