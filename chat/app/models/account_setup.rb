class AccountSetup
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :account_name, :string
  attribute :user_name, :string
  attribute :email_address, :string
  attribute :password, :string
  attribute :password_confirmation, :string

  validates :account_name, presence: true
  validates :user_name, presence: true
  validates :email_address, presence: true
  validates :password, presence: true
  validate :passwords_match

  def save
    return false unless valid?

    ActiveRecord::Base.transaction do
      create_account
      create_admin_user
      create_general_room
    end
    true
  rescue ActiveRecord::RecordInvalid => e
    copy_errors_from(e.record)
    false
  end

  attr_reader :account, :user

  private

  def create_account
    @account = Account.create!(name: account_name)
  end

  def create_admin_user
    @user = @account.users.create!(
      name: user_name,
      email_address: email_address,
      password: password,
      password_confirmation: password_confirmation,
      admin: true
    )
  end

  def create_general_room
    general = @account.rooms.create!(name: "General")
    general.memberships.create!(user: @user)
  end

  def passwords_match
    return if password == password_confirmation
    errors.add(:password_confirmation, "doesn't match Password")
  end

  def copy_errors_from(record)
    record.errors.each do |error|
      errors.add(error.attribute, error.message)
    end
  end
end
