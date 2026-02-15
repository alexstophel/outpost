class RoomRead < ApplicationRecord
  belongs_to :user
  belongs_to :room

  validates :user_id, uniqueness: { scope: :room_id }

  # Check if there are unread messages
  def unread?
    room.messages.where("created_at > ?", last_read_at).exists?
  end

  # Mark as read now
  def mark_read!
    update!(last_read_at: Time.current)
  end
end
