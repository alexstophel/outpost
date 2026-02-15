class RoomRead < ApplicationRecord
  belongs_to :user
  belongs_to :room

  validates :user_id, uniqueness: { scope: :room_id }

  # Check if there are unread messages
  def unread?
    room.has_messages_since?(last_read_at)
  end

  # Mark as read now
  def mark_read!
    update!(last_read_at: Time.current)
  end
end
