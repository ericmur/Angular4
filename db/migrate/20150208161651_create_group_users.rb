class CreateGroupUsers < ActiveRecord::Migration
  def change
    create_table :group_users do |t|
      t.integer :group_id
      t.integer :user_id
      t.string  :label
      t.string  :name
      t.string  :email
      t.string  :phone
      t.string  :phone_normalized
      t.datetime :dob
      t.timestamps
    end

    add_index :group_users, [:group_id, :user_id], :unique => true
    add_index :group_users, :user_id
  end
end
