class SetupController < ApplicationController
  allow_unauthenticated_access
  before_action :require_no_account

  def new
    @account = Account.new
    @user = User.new
  end

  def create
    @account = Account.new(account_params)
    @user = @account.users.build(user_params.merge(admin: true))

    if @account.save
      create_general_room(@account, @user)
      start_new_session_for @user
      redirect_to root_path, notice: "Welcome to Outpost!"
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def require_no_account
    redirect_to root_path if Account.setup?
  end

  def account_params
    params.require(:account).permit(:name)
  end

  def user_params
    params.require(:user).permit(:email_address, :password, :password_confirmation)
  end

  def create_general_room(account, user)
    general = account.rooms.create!(name: "General")
    general.memberships.create!(user: user)
  end
end
