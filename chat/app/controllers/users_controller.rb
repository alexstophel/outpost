class UsersController < ApplicationController
  include AdminAuthorization

  before_action :require_admin
  before_action :set_user

  def update
    @user.update!(admin: params[:admin])
    head :ok
  end

  def destroy
    if @user == Current.user
      redirect_to settings_path, alert: "You cannot delete yourself."
    else
      @user.destroy
      redirect_to settings_path, notice: "User deleted."
    end
  end

  private

  def set_user
    @user = Current.user.account.users.find(params[:id])
  end
end
