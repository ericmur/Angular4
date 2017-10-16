class AddOauthTokenPrivateKeyToUser < ActiveRecord::Migration
  def change
    add_column :users, :oauth_token_private_key, :string
  end
end
