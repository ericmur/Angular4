class AddPasswordPrivateKeyToUsers < ActiveRecord::Migration
  def change
    add_column :users, :password_private_key, :text
  end
end
