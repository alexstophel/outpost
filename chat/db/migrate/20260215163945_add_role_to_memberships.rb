class AddRoleToMemberships < ActiveRecord::Migration[8.1]
  def change
    add_column :memberships, :role, :string, null: false, default: "member"
    add_index :memberships, :role
  end
end
