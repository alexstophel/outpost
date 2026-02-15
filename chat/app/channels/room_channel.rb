class RoomChannel < ApplicationCable::Channel
  def subscribed
    room = Room.find(params[:id])

    if current_user.rooms.include?(room)
      stream_for room
    else
      reject
    end
  end
end
