class SetupController < ApplicationController
  allow_unauthenticated_access
  before_action :require_no_account

  def new
    @setup = AccountSetup.new
  end

  def create
    @setup = AccountSetup.new(setup_params)

    if @setup.save
      start_new_session_for @setup.user
      redirect_to root_path, notice: "Welcome to Outpost!"
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def require_no_account
    redirect_to root_path if Account.setup?
  end

  # Maps nested params from two different namespaces (account, user) to
  # flat attributes for AccountSetup. This approach is intentional as the
  # form has separate fieldsets for account and user information.
  def setup_params
    {
      account_name: params[:account][:name],
      user_name: params[:user][:name],
      email_address: params[:user][:email_address],
      password: params[:user][:password],
      password_confirmation: params[:user][:password_confirmation]
    }
  end
end
