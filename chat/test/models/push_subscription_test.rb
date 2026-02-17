require "test_helper"

class PushSubscriptionTest < ActiveSupport::TestCase
  # Associations

  test "belongs to user" do
    subscription = push_subscriptions(:one)

    assert_instance_of User, subscription.user
    assert_equal users(:one), subscription.user
  end

  # Validations

  test "validates presence of endpoint" do
    subscription = PushSubscription.new(
      user: users(:one),
      endpoint: nil,
      p256dh: "test-key",
      auth: "test-auth"
    )

    assert_not subscription.valid?
    assert_includes subscription.errors[:endpoint], "can't be blank"
  end

  test "validates uniqueness of endpoint" do
    existing = push_subscriptions(:one)
    duplicate = PushSubscription.new(
      user: users(:two),
      endpoint: existing.endpoint,
      p256dh: "different-key",
      auth: "different-auth"
    )

    assert_not duplicate.valid?
    assert_includes duplicate.errors[:endpoint], "has already been taken"
  end

  test "validates presence of p256dh" do
    subscription = PushSubscription.new(
      user: users(:one),
      endpoint: "https://push.example.com/new",
      p256dh: nil,
      auth: "test-auth"
    )

    assert_not subscription.valid?
    assert_includes subscription.errors[:p256dh], "can't be blank"
  end

  test "validates presence of auth" do
    subscription = PushSubscription.new(
      user: users(:one),
      endpoint: "https://push.example.com/new",
      p256dh: "test-key",
      auth: nil
    )

    assert_not subscription.valid?
    assert_includes subscription.errors[:auth], "can't be blank"
  end

  test "valid subscription with all required attributes" do
    subscription = PushSubscription.new(
      user: users(:one),
      endpoint: "https://push.example.com/unique-endpoint",
      p256dh: "test-key",
      auth: "test-auth"
    )

    assert subscription.valid?
  end

  # Class methods

  test "configured? returns false when VAPID keys are missing" do
    original_public = ENV["VAPID_PUBLIC_KEY"]
    original_private = ENV["VAPID_PRIVATE_KEY"]

    ENV["VAPID_PUBLIC_KEY"] = nil
    ENV["VAPID_PRIVATE_KEY"] = nil

    assert_not PushSubscription.configured?
  ensure
    ENV["VAPID_PUBLIC_KEY"] = original_public
    ENV["VAPID_PRIVATE_KEY"] = original_private
  end

  test "configured? returns false when only public key is present" do
    original_public = ENV["VAPID_PUBLIC_KEY"]
    original_private = ENV["VAPID_PRIVATE_KEY"]

    ENV["VAPID_PUBLIC_KEY"] = "test-public-key"
    ENV["VAPID_PRIVATE_KEY"] = nil

    assert_not PushSubscription.configured?
  ensure
    ENV["VAPID_PUBLIC_KEY"] = original_public
    ENV["VAPID_PRIVATE_KEY"] = original_private
  end

  test "configured? returns true when both VAPID keys are present" do
    original_public = ENV["VAPID_PUBLIC_KEY"]
    original_private = ENV["VAPID_PRIVATE_KEY"]

    ENV["VAPID_PUBLIC_KEY"] = "test-public-key"
    ENV["VAPID_PRIVATE_KEY"] = "test-private-key"

    assert PushSubscription.configured?
  ensure
    ENV["VAPID_PUBLIC_KEY"] = original_public
    ENV["VAPID_PRIVATE_KEY"] = original_private
  end

  test "vapid_public_key returns ENV value" do
    original = ENV["VAPID_PUBLIC_KEY"]
    ENV["VAPID_PUBLIC_KEY"] = "my-test-public-key"

    assert_equal "my-test-public-key", PushSubscription.vapid_public_key
  ensure
    ENV["VAPID_PUBLIC_KEY"] = original
  end

  test "vapid_private_key returns ENV value" do
    original = ENV["VAPID_PRIVATE_KEY"]
    ENV["VAPID_PRIVATE_KEY"] = "my-test-private-key"

    assert_equal "my-test-private-key", PushSubscription.vapid_private_key
  ensure
    ENV["VAPID_PRIVATE_KEY"] = original
  end

  test "vapid_credentials returns hash with both keys" do
    original_public = ENV["VAPID_PUBLIC_KEY"]
    original_private = ENV["VAPID_PRIVATE_KEY"]

    ENV["VAPID_PUBLIC_KEY"] = "pub-key"
    ENV["VAPID_PRIVATE_KEY"] = "priv-key"

    credentials = PushSubscription.vapid_credentials

    assert_equal "pub-key", credentials[:public_key]
    assert_equal "priv-key", credentials[:private_key]
  ensure
    ENV["VAPID_PUBLIC_KEY"] = original_public
    ENV["VAPID_PRIVATE_KEY"] = original_private
  end

  # send_notification

  test "send_notification does nothing when not configured" do
    original_public = ENV["VAPID_PUBLIC_KEY"]
    original_private = ENV["VAPID_PRIVATE_KEY"]

    ENV["VAPID_PUBLIC_KEY"] = nil
    ENV["VAPID_PRIVATE_KEY"] = nil

    subscription = push_subscriptions(:one)

    # Should not raise and should not call WebPush
    assert_nothing_raised do
      subscription.send_notification(title: "Test", body: "Message")
    end
  ensure
    ENV["VAPID_PUBLIC_KEY"] = original_public
    ENV["VAPID_PRIVATE_KEY"] = original_private
  end

  # Dependent destroy

  test "is destroyed when user is destroyed" do
    user = users(:one)
    subscription_count_before = user.push_subscriptions.count

    assert subscription_count_before > 0

    user.destroy

    assert_equal 0, PushSubscription.where(user_id: user.id).count
  end
end
