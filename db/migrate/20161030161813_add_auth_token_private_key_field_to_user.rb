class AddAuthTokenPrivateKeyFieldToUser < ActiveRecord::Migration
  def change
    add_column :users, :auth_token_private_key, :string
  end
end
