class AddDocytBotAccessExpiryToDocument < ActiveRecord::Migration
  def change
    add_column :documents, :docyt_bot_access_expires_at, :datetime
  end
end
