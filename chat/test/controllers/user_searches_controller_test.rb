require "test_helper"

class UserSearchesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    @other_user = users(:two)
  end

  test "index returns users matching search query" do
    sign_in_as @user

    get user_searches_path, params: { q: "Two" }, as: :json

    assert_response :success
    json = JSON.parse(response.body)
    assert_equal 1, json.length
    assert_equal @other_user.id, json.first["id"]
    assert_equal @other_user.name, json.first["name"]
  end

  test "index excludes current user from results" do
    sign_in_as @user

    get user_searches_path, params: { q: "User" }, as: :json

    assert_response :success
    json = JSON.parse(response.body)
    user_ids = json.map { |u| u["id"] }
    assert_not_includes user_ids, @user.id
    assert_includes user_ids, @other_user.id
  end

  test "index returns empty array when no matches" do
    sign_in_as @user

    get user_searches_path, params: { q: "Nonexistent" }, as: :json

    assert_response :success
    json = JSON.parse(response.body)
    assert_equal [], json
  end

  test "index returns all peers when query is empty" do
    sign_in_as @user

    get user_searches_path, params: { q: "" }, as: :json

    assert_response :success
    json = JSON.parse(response.body)
    assert_equal 1, json.length
    assert_equal @other_user.id, json.first["id"]
  end

  test "index limits results to 10" do
    sign_in_as @user
    12.times do |i|
      @user.account.users.create!(
        name: "Test User #{i}",
        email_address: "test#{i}@example.com",
        password: "password123"
      )
    end

    get user_searches_path, params: { q: "Test" }, as: :json

    assert_response :success
    json = JSON.parse(response.body)
    assert_equal 10, json.length
  end

  test "index only returns users from same account" do
    sign_in_as @user
    other_account = Account.create!(name: "Other Account")
    external_user = other_account.users.create!(
      name: "External User",
      email_address: "external@example.com",
      password: "password123"
    )

    get user_searches_path, params: { q: "External" }, as: :json

    assert_response :success
    json = JSON.parse(response.body)
    assert_equal [], json
  end

  test "index includes avatar_url when user has avatar" do
    sign_in_as @user

    get user_searches_path, params: { q: "Two" }, as: :json

    assert_response :success
    json = JSON.parse(response.body)
    assert_includes json.first.keys, "avatar_url"
  end

  test "index requires authentication" do
    get user_searches_path, params: { q: "User" }, as: :json

    assert_redirected_to new_session_path
  end
end
