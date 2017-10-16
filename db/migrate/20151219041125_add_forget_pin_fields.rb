class AddForgetPinFields < ActiveRecord::Migration
  def change
    add_column :users, :forgot_pin_token, :string
    add_column :users, :forgot_pin_token_sent_at, :datetime
    add_column :users, :forgot_pin_confirmed_at, :datetime
  end
end
