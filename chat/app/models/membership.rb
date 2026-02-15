class Membership < ApplicationRecord
  belongs_to :room
  belongs_to :user

  attribute :role, :string, default: "member"
  enum :role, { member: "member", admin: "admin" }

  validates :user_id, uniqueness: { scope: :room_id }

  scope :admins, -> { where(role: :admin) }
end
