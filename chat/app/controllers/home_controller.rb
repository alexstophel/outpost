class HomeController < ApplicationController
  allow_unauthenticated_access only: :index
  before_action :redirect_based_on_state, only: :index

  def index
    # Redirect authenticated users to their first room (General)
    general = Current.user.rooms.first
    if general
      redirect_to room_path(general)
    end
  end

  private

  def redirect_based_on_state
    unless Account.setup?
      redirect_to new_setup_path
    else
      redirect_to new_session_path unless authenticated?
    end
  end
end
