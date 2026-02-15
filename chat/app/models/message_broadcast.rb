class MessageBroadcast
  def initialize(message)
    @message = message
  end

  def deliver
    @message.broadcast_append_to @message.room,
      target: "messages",
      partial: "messages/message",
      locals: { message: preloaded_message }
  end

  private

  def preloaded_message
    Message.includes(user: { avatar_attachment: :blob }).find(@message.id)
  end
end
