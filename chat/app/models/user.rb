class User < ApplicationRecord
  MAX_FAILED_ATTEMPTS = 5
  LOCKOUT_DURATION = 30.minutes

  has_secure_password
  has_many :sessions, dependent: :destroy
  has_many :memberships, dependent: :destroy
  has_many :rooms, through: :memberships
  has_many :messages, dependent: :destroy
  has_many :room_reads, dependent: :destroy
  belongs_to :account

  scope :search_by_name, ->(query) {
    where("name LIKE ?", "%#{sanitize_sql_like(query)}%") if query.present?
  }

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

  # Other users in the same account (excluding self)
  def account_peers
    account.users.where.not(id: id)
  end

  # Get direct message rooms, ordered by most recent activity
  def direct_message_rooms
    rooms.direct_messages.left_joins(:messages)
      .group("rooms.id")
      .order(Arel.sql("MAX(messages.created_at) DESC NULLS LAST"))
  end

  # Get direct message rooms with unread status preloaded (avoids N+1)
  # Returns rooms with a `has_unread` attribute
  def direct_message_rooms_with_unread_status
    rooms.direct_messages
      .left_joins(:messages)
      .left_joins(:room_reads)
      .where("room_reads.user_id = ? OR room_reads.user_id IS NULL", id)
      .group("rooms.id")
      .select(
        "rooms.*",
        "MAX(messages.created_at) as last_message_at_cache",
        unread_status_sql
      )
      .order(Arel.sql("MAX(messages.created_at) DESC NULLS LAST"))
  end

  # Get channel rooms
  def channel_rooms
    rooms.channels
  end

  # Check if a room has unread messages for this user
  def has_unread_in?(room)
    room_read = room_reads.find_by(room: room)
    return true unless room_read # Never read = unread
    room_read.unread?
  end

  # Mark a room as read
  def mark_room_as_read!(room)
    room_read = room_reads.find_or_initialize_by(room: room)
    room_read.update!(last_read_at: Time.current)
  end

  # Check if user is an admin of a room
  def admin_of?(room)
    memberships.find_by(room: room)&.admin?
  end

  # Check if user is a member of a room
  def member_of?(room)
    rooms.include?(room)
  end

  # Get membership for a specific room
  def membership_for(room)
    memberships.find_by(room: room)
  end

  private

  def unread_status_sql
    # Room is unread if:
    # 1. No room_read exists (never read), OR
    # 2. There's a message newer than last_read_at
    <<~SQL.squish
      CASE
        WHEN MAX(room_reads.last_read_at) IS NULL THEN 1
        WHEN MAX(messages.created_at) > MAX(room_reads.last_read_at) THEN 1
        ELSE 0
      END as has_unread
    SQL
  end

  def avatar_file_size
    return unless avatar.attached?

    if avatar.blob.byte_size > 5.megabytes
      errors.add(:avatar, "must be less than 5MB")
    end
  end
end
