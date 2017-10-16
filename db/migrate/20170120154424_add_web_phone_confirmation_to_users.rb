class AddWebPhoneConfirmationToUsers < ActiveRecord::Migration
  def change
    add_column :users, :web_phone_confirmed_at, :datetime
    add_column :users, :web_phone_confirmation_token, :string
    add_column :users, :web_phone_confirmation_sent_at, :datetime
  end
end
