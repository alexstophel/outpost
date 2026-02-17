# This index improves lookup performance for finding rooms by name within an account.
# Particularly useful for finding the "General" room when new users join via invite link.
class AddIndexToRoomsAccountIdAndName < ActiveRecord::Migration[8.1]
  def change
    add_index :rooms, [ :account_id, :name ]
  end
end
