class RenameConversationsToRooms < ActiveRecord::Migration[8.1]
  def change
    rename_table :conversations, :rooms
    rename_column :memberships, :conversation_id, :room_id
    rename_column :messages, :conversation_id, :room_id
  end
end
