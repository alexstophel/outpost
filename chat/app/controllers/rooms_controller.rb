class RoomsController < ApplicationController
  before_action :set_room

  def show
    @messages = @room.messages.includes(:user).order(:created_at)
    @message = Message.new

    # Prepare sidebar data
    @channels = Current.user.channel_rooms
    @direct_messages = Current.user.direct_message_rooms.includes(:users)

    # Mark room as read
    Current.user.mark_room_as_read!(@room)
  end

  private

  def set_room
    @room = Current.user.rooms.find(params[:id])
  end
end
