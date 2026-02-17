class PushSubscription < ApplicationRecord
  WEBPUSH_TIMEOUT_SECONDS = 10

  belongs_to :user

  validates :endpoint, presence: true, uniqueness: true
  validates :p256dh, presence: true
  validates :auth, presence: true

  # Send a push notification to this subscription
  def send_notification(title:, body:, path: "/")
    return unless PushSubscription.configured?

    message = {
      title: title,
      options: {
        body: body,
        data: { path: path },
        tag: path, # Collapse notifications for same path
        renotify: true
      }
    }

    Timeout.timeout(WEBPUSH_TIMEOUT_SECONDS) do
      WebPush.payload_send(
        message: message.to_json,
        endpoint: endpoint,
        p256dh: p256dh,
        auth: auth,
        vapid: PushSubscription.vapid_credentials
      )
    end
  rescue WebPush::ExpiredSubscription, WebPush::InvalidSubscription
    # Subscription is no longer valid, remove it
    destroy
  rescue WebPush::Error, Timeout::Error => e
    Rails.logger.error "Push notification failed: #{e.message}"
    # TODO: Add error tracking when service is configured (e.g., Sentry, Honeybadger)
    # ErrorTracker.notify(e, context: { endpoint: endpoint, user_id: user_id })
  end

  class << self
    def configured?
      vapid_public_key.present? && vapid_private_key.present?
    end

    def vapid_public_key
      ENV["VAPID_PUBLIC_KEY"]
    end

    def vapid_private_key
      ENV["VAPID_PRIVATE_KEY"]
    end

    def vapid_credentials
      {
        public_key: vapid_public_key,
        private_key: vapid_private_key
      }
    end
  end
end
