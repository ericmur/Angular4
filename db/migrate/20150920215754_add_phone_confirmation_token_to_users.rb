class AddPhoneConfirmationTokenToUsers < ActiveRecord::Migration
  def change
    add_column :users, :phone_confirmation_token, :string
    add_column :users, :phone_confirmation_sent_at, :datetime
    add_index :users, :phone_confirmation_token, :unique => true
  end
end
