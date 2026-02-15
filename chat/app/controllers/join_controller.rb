class JoinController < ApplicationController
  allow_unauthenticated_access
  before_action :set_account
  before_action :redirect_if_authenticated

  def show
    @user = User.new
  end

  def create
    @user = @account.users.build(user_params)

    if @user.save
      add_to_general_room(@user)
      start_new_session_for @user
      redirect_to root_path, notice: "Welcome to #{@account.name}!"
    else
      render :show, status: :unprocessable_entity
    end
  end

  private

  def set_account
    @account = Account.find_by(invite_token: params[:token])
    redirect_to root_path, alert: "Invalid invite link." unless @account
  end

  def redirect_if_authenticated
    redirect_to root_path if authenticated?
  end

  def user_params
    params.require(:user).permit(:email_address, :password, :password_confirmation)
  end

  def add_to_general_room(user)
    general = @account.rooms.find_by(name: "General")
    general.memberships.create!(user: user) if general
  end
end
