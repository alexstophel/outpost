require "test_helper"

class ProfilesControllerTest < ActionDispatch::IntegrationTest
  test "show requires authentication" do
    get profile_path

    assert_redirected_to new_session_path
  end

  test "show renders profile for authenticated user" do
    sign_in_as users(:one)

    get profile_path

    assert_response :success
    assert_select "h1", text: /Profile/i
  end

  test "show displays user email" do
    sign_in_as users(:one)

    get profile_path

    assert_select "p", text: /one@example.com/
  end

  test "update requires authentication" do
    patch profile_path, params: { user: { name: "New Name" } }

    assert_redirected_to new_session_path
  end

  test "update changes user name" do
    user = users(:one)
    sign_in_as user

    patch profile_path, params: { user: { name: "Updated Name" } }

    assert_redirected_to profile_path
    assert_equal "Updated Name", user.reload.name
  end

  test "update with invalid name renders form" do
    user = users(:one)
    sign_in_as user

    patch profile_path, params: { user: { name: "" } }

    assert_response :unprocessable_entity
    assert_not_equal "", user.reload.name
  end

  test "update does not allow changing email" do
    user = users(:one)
    original_email = user.email_address
    sign_in_as user

    patch profile_path, params: { user: { name: "New Name", email_address: "hacked@example.com" } }

    assert_equal original_email, user.reload.email_address
  end
end
