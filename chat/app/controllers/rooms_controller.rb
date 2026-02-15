class RoomsController < ApplicationController
  before_action :set_room

  def show
    @messages = @room.messages.includes(:user).order(:created_at)
    @message = Message.new
  end

  private

  def set_room
    @room = Current.user.rooms.find(params[:id])
  end
end
