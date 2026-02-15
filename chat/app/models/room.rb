class Room < ApplicationRecord
  belongs_to :account
  has_many :memberships, dependent: :destroy
  has_many :users, through: :memberships
  has_many :messages, dependent: :destroy
  has_many :room_reads, dependent: :destroy

  attribute :room_type, :string, default: "channel"
  enum :room_type, { channel: "channel", direct_message: "direct_message" }

  attribute :visibility, :string, default: "public"
  enum :visibility, { public_room: "public", private_room: "private" }, prefix: :visibility

  scope :channels, -> { where(room_type: :channel) }
  scope :direct_messages, -> { where(room_type: :direct_message) }

  # Public rooms that a user can see and join (not already a member)
  scope :joinable_by, ->(user) {
    channels.where(visibility: "public", account: user.account)
      .where.not(id: user.room_ids)
  }

  # Rooms visible to a user (public or member of)
  scope :visible_to, ->(user) {
    channels
      .left_joins(:memberships)
      .where(account: user.account)
      .where("rooms.visibility = 'public' OR memberships.user_id = ?", user.id)
      .distinct
  }

  validates :name, presence: true

  # General room is the default room everyone joins
  def default_room?
    name.downcase == "general"
  end

  # General room cannot be deleted
  def deletable?
    !default_room?
  end

  # General room membership cannot be modified
  def membership_editable?
    !default_room?
  end

  # For DMs, return the other user's name; for channels, return the room name
  def display_name_for(user)
    if direct_message?
      other_user = users.where.not(id: user.id).first
      other_user&.name || name
    else
      name
    end
  end

  # Get the other participant in a DM
  def other_participant(user)
    return nil unless direct_message?
    users.where.not(id: user.id).first
  end

  # Find the most recent message timestamp for ordering
  def last_message_at
    messages.maximum(:created_at) || created_at
  end

  # Find or create a DM between two users
  def self.find_or_create_dm(user_a, user_b, account)
    # Find existing DM between these exact two users
    existing = direct_messages
      .where(account: account)
      .joins(:memberships)
      .where(memberships: { user_id: [user_a.id, user_b.id] })
      .group("rooms.id")
      .having("COUNT(DISTINCT memberships.user_id) = 2")
      .having("COUNT(memberships.id) = 2")
      .first

    return existing if existing

    # Create new DM
    transaction do
      room = create!(
        account: account,
        room_type: :direct_message,
        name: "DM-#{[user_a.id, user_b.id].sort.join('-')}"
      )
      room.memberships.create!(user: user_a)
      room.memberships.create!(user: user_b)
      room
    end
  end
end
