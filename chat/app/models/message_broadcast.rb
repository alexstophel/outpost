class MessageBroadcast
  def initialize(message)
    @message = message
  end

  def deliver_create
    # Remove empty state if present
    @message.broadcast_remove_to @message.room, target: "empty-room-state"

    # Append the new message
    @message.broadcast_append_to @message.room,
      target: "messages",
      partial: "messages/message",
      locals: { message: preloaded_message }
  end

  def deliver_update
    @message.broadcast_replace_to @message.room,
      target: ActionView::RecordIdentifier.dom_id(@message),
      partial: "messages/message",
      locals: { message: preloaded_message }
  end

  def deliver_destroy
    @message.broadcast_remove_to @message.room,
      target: ActionView::RecordIdentifier.dom_id(@message)

    # Show empty state if this was the last message
    if @message.room.messages.count == 0
      @message.broadcast_append_to @message.room,
        target: "messages",
        partial: "rooms/empty_state",
        locals: { room: @message.room }
    end
  end

  private

  def preloaded_message
    Message.includes(user: { avatar_attachment: :blob }).find(@message.id)
  end
end
