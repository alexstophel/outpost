class CreateRoomReads < ActiveRecord::Migration[8.1]
  def change
    create_table :room_reads do |t|
      t.references :user, null: false, foreign_key: true
      t.references :room, null: false, foreign_key: true
      t.datetime :last_read_at, null: false

      t.timestamps
    end

    add_index :room_reads, [:user_id, :room_id], unique: true
  end
end
