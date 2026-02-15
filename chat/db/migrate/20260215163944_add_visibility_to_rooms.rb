class AddVisibilityToRooms < ActiveRecord::Migration[8.1]
  def change
    add_column :rooms, :visibility, :string, null: false, default: "public"
    add_index :rooms, :visibility
  end
end
