class DirectMessagesController < ApplicationController
  before_action :require_authentication

  def create
    other_user = Current.user.account_peers.find(params[:user_id])
    room = Room.find_or_create_dm(Current.user, other_user, Current.user.account)

    redirect_to room_path(room)
  end
end
