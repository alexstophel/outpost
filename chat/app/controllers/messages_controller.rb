class MessagesController < ApplicationController
  before_action :set_room

  def create
    @message = @room.messages.build(message_params)
    @message.user = Current.user

    respond_to do |format|
      if @message.save
        format.turbo_stream
        format.html { redirect_to @room }
      else
        format.turbo_stream { render turbo_stream: turbo_stream.replace("message_form", partial: "messages/form", locals: { room: @room, message: @message }) }
        format.html { redirect_to @room, alert: "Message could not be sent." }
      end
    end
  end

  private

  def set_room
    @room = Current.user.rooms.find(params[:room_id])
  end

  def message_params
    params.require(:message).permit(:body)
  end
end
