require "test_helper"

class MembershipsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    @other_user = users(:two)
    @general = rooms(:general)
    @random = rooms(:random)
  end

  # CREATE - Join public room

  test "create allows user to join public room" do
    sign_in_as @other_user
    public_room = Room.create!(name: "Public Room", account: accounts(:one), visibility: "public")

    assert_difference "Membership.count", 1 do
      post room_memberships_path(public_room)
    end

    assert_redirected_to room_path(public_room)
    assert @other_user.member_of?(public_room)
  end

  test "create redirects if already a member" do
    sign_in_as @user

    assert_no_difference "Membership.count" do
      post room_memberships_path(@general)
    end

    assert_redirected_to room_path(@general)
  end

  test "create does not allow joining private room without admin" do
    sign_in_as @other_user
    private_room = Room.create!(name: "Private Room", account: accounts(:one), visibility: "private")
    private_room.memberships.create!(user: @user, role: :admin)

    assert_no_difference "Membership.count" do
      post room_memberships_path(private_room)
    end

    assert_redirected_to room_path(private_room)
  end

  # CREATE - Admin adding member

  test "create allows admin to add member to private room" do
    sign_in_as @user
    private_room = Room.create!(name: "Private Room", account: accounts(:one), visibility: "private")
    private_room.memberships.create!(user: @user, role: :admin)

    assert_difference "Membership.count", 1 do
      post room_memberships_path(private_room), params: { user_id: @other_user.id }, as: :json
    end

    assert_response :ok
    assert @other_user.member_of?(private_room)
  end

  test "create returns 404 for non-existent user" do
    sign_in_as @user
    private_room = Room.create!(name: "Private Room", account: accounts(:one), visibility: "private")
    private_room.memberships.create!(user: @user, role: :admin)

    post room_memberships_path(private_room), params: { user_id: 999999 }, as: :json

    assert_response :not_found
  end

  test "create returns 422 if user already a member" do
    sign_in_as @user
    private_room = Room.create!(name: "Test Room", account: accounts(:one), visibility: "private")
    private_room.memberships.create!(user: @user, role: :admin)
    private_room.memberships.create!(user: @other_user, role: :member)

    post room_memberships_path(private_room), params: { user_id: @other_user.id }, as: :json

    assert_response :unprocessable_entity
  end

  # CREATE - General room restriction

  test "create redirects when trying to modify general room membership" do
    sign_in_as @user

    post room_memberships_path(@general)

    assert_redirected_to room_path(@general)
  end

  # DESTROY - Leave room

  test "destroy allows user to leave room" do
    sign_in_as @user
    membership = @user.membership_for(@random)

    assert_difference "Membership.count", -1 do
      delete room_membership_path(@random, membership)
    end

    assert_redirected_to root_path
    assert_not @user.reload.member_of?(@random)
  end

  test "destroy prevents last admin from leaving" do
    sign_in_as @user
    private_room = Room.create!(name: "Admin Only", account: accounts(:one), visibility: "private")
    membership = private_room.memberships.create!(user: @user, role: :admin)

    assert_no_difference "Membership.count" do
      delete room_membership_path(private_room, membership)
    end

    assert_redirected_to room_path(private_room)
  end

  test "destroy allows admin to leave if another admin exists" do
    sign_in_as @user
    private_room = Room.create!(name: "Two Admins", account: accounts(:one), visibility: "private")
    membership = private_room.memberships.create!(user: @user, role: :admin)
    private_room.memberships.create!(user: @other_user, role: :admin)

    assert_difference "Membership.count", -1 do
      delete room_membership_path(private_room, membership)
    end

    assert_redirected_to root_path
  end

  # DESTROY - Admin removing member

  test "destroy allows admin to remove member" do
    sign_in_as @user
    private_room = Room.create!(name: "Admin Room", account: accounts(:one), visibility: "private")
    private_room.memberships.create!(user: @user, role: :admin)
    other_membership = private_room.memberships.create!(user: @other_user, role: :member)

    assert_difference "Membership.count", -1 do
      delete room_membership_path(private_room, other_membership), as: :json
    end

    assert_response :ok
  end

  test "destroy prevents non-admin from removing others" do
    sign_in_as @other_user
    private_room = Room.create!(name: "Admin Room", account: accounts(:one), visibility: "private")
    private_room.memberships.create!(user: @user, role: :admin)
    private_room.memberships.create!(user: @other_user, role: :member)
    admin_membership = @user.membership_for(private_room)

    assert_no_difference "Membership.count" do
      delete room_membership_path(private_room, admin_membership)
    end

    assert_redirected_to room_path(private_room)
  end

  test "destroy redirects when trying to modify general room membership" do
    sign_in_as @user
    membership = @user.membership_for(@general)

    assert_no_difference "Membership.count" do
      delete room_membership_path(@general, membership)
    end

    assert_redirected_to room_path(@general)
  end

  # Authentication

  test "create requires authentication" do
    post room_memberships_path(@random)

    assert_redirected_to new_session_path
  end

  test "destroy requires authentication" do
    membership = memberships(:user_one_random)

    delete room_membership_path(@random, membership)

    assert_redirected_to new_session_path
  end

  # Account scoping security

  test "create returns 404 for room in different account" do
    sign_in_as @user
    other_account = Account.create!(name: "Other Account")
    other_room = other_account.rooms.create!(name: "Other Room", visibility: "public")

    post room_memberships_path(other_room)

    assert_response :not_found
  end

  test "destroy returns 404 for room in different account" do
    sign_in_as @user
    other_account = Account.create!(name: "Other Account")
    other_room = other_account.rooms.create!(name: "Other Room")
    other_user = other_account.users.create!(
      name: "Other User",
      email_address: "other@example.com",
      password: "password123"
    )
    other_membership = other_room.memberships.create!(user: other_user)

    delete room_membership_path(other_room, other_membership)

    assert_response :not_found
  end
end
