require "test_helper"

class PushNotificationJobTest < ActiveJob::TestCase
  setup do
    @user = users(:one)
  end

  test "does nothing when push not configured" do
    original_public = ENV["VAPID_PUBLIC_KEY"]
    ENV["VAPID_PUBLIC_KEY"] = nil

    # Should not raise
    assert_nothing_raised do
      PushNotificationJob.perform_now(
        @user.id,
        title: "Test",
        body: "Test body"
      )
    end
  ensure
    ENV["VAPID_PUBLIC_KEY"] = original_public
  end

  test "does nothing when user not found" do
    original_public = ENV["VAPID_PUBLIC_KEY"]
    original_private = ENV["VAPID_PRIVATE_KEY"]
    ENV["VAPID_PUBLIC_KEY"] = "test_key"
    ENV["VAPID_PRIVATE_KEY"] = "test_key"

    # Should not raise for non-existent user
    assert_nothing_raised do
      PushNotificationJob.perform_now(
        999999,
        title: "Test",
        body: "Test body"
      )
    end
  ensure
    ENV["VAPID_PUBLIC_KEY"] = original_public
    ENV["VAPID_PRIVATE_KEY"] = original_private
  end

  test "enqueues on default queue" do
    assert_equal "default", PushNotificationJob.new.queue_name
  end
end
