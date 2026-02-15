class User < ApplicationRecord
  MAX_FAILED_ATTEMPTS = 5
  LOCKOUT_DURATION = 30.minutes

  has_secure_password
  has_many :sessions, dependent: :destroy
  has_many :memberships, dependent: :destroy
  has_many :rooms, through: :memberships
  has_many :messages, dependent: :destroy
  belongs_to :account

  has_one_attached :avatar

  normalizes :email_address, with: ->(e) { e.strip.downcase }

  validates :email_address, presence: true, uniqueness: true
  validates :name, presence: true, format: { with: /\A\S.*\z/, message: "must contain non-whitespace characters" }
  validate :avatar_file_size

  def locked?
    locked_at.present? && locked_at > LOCKOUT_DURATION.ago
  end

  def lock_access!
    update!(locked_at: Time.current, failed_login_attempts: MAX_FAILED_ATTEMPTS)
  end

  def unlock_access!
    update!(locked_at: nil, failed_login_attempts: 0)
  end

  def record_failed_login!
    increment!(:failed_login_attempts)
    lock_access! if failed_login_attempts >= MAX_FAILED_ATTEMPTS
  end

  def record_successful_login!
    update!(failed_login_attempts: 0, locked_at: nil) if failed_login_attempts > 0
  end

  private

  def avatar_file_size
    return unless avatar.attached?

    if avatar.blob.byte_size > 5.megabytes
      errors.add(:avatar, "must be less than 5MB")
    end
  end
end

