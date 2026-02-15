class AddRoomTypeToRooms < ActiveRecord::Migration[8.1]
  def change
    add_column :rooms, :room_type, :string, null: false, default: "channel"
    add_index :rooms, :room_type
  end
end
