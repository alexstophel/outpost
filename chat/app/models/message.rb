class Message < ApplicationRecord
  belongs_to :room
  belongs_to :user

  validates :body, presence: true

  after_create_commit :broadcast_message

  private

  def broadcast_message
    MessageBroadcast.new(self).deliver
  end
end
