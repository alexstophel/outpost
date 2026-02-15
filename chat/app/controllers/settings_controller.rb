class SettingsController < ApplicationController
  include AdminAuthorization

  before_action :require_admin

  def show
    @account = Current.user.account
    @users = @account.users.order(:created_at)
  end

  def regenerate_invite_token
    Current.user.account.regenerate_invite_token!
    redirect_to settings_path, notice: "Invite link regenerated."
  end
end
