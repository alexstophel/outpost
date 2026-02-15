class Account < ApplicationRecord
  has_many :users, dependent: :destroy
  has_many :rooms, dependent: :destroy

  validates :name, presence: true

  before_create :generate_invite_token

  def self.setup?
    exists?
  end

  def regenerate_invite_token!
    generate_invite_token
    save!
  end

  def invite_url(host:)
    "#{host}/join/#{invite_token}"
  end

  private

  def generate_invite_token
    self.invite_token = SecureRandom.alphanumeric(16)
  end
end
