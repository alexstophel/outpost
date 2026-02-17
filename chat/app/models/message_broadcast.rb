class MessageBroadcast
  PUSH_NOTIFICATION_BODY_MAX_LENGTH = 100

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

    # For DMs: broadcast to recipient's sidebar if this is the first message
    broadcast_new_dm_to_sidebar

    # Send push notifications to other room members
    send_push_notifications
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

  def send_push_notifications
    return unless PushSubscription.configured?

    room = @message.room
    sender = @message.user

    # Get all room members except the sender
    recipients = room.users.where.not(id: sender.id)

    # Prepare notification content
    title = room.direct_message? ? sender.name : "##{room.name}"
    body = truncate_body(@message.body)
    path = "/rooms/#{room.id}"

    # Enqueue push notification jobs for each recipient
    recipients.find_each do |recipient|
      PushNotificationJob.perform_later(
        recipient.id,
        title: title,
        body: body,
        path: path
      )
    end
  end

  def truncate_body(text, max_length: PUSH_NOTIFICATION_BODY_MAX_LENGTH)
    return text if text.length <= max_length
    "#{text[0, max_length - 1]}..."
  end

  def broadcast_new_dm_to_sidebar
    room = @message.room
    return unless room.direct_message?

    # Only broadcast on first message in the DM
    return unless room.messages.count == 1

    sender = @message.user
    recipient = room.other_participant(sender)
    return unless recipient

    # Broadcast to recipient's sidebar
    room.broadcast_to_user_sidebar(recipient)
  end
end
