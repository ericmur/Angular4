class AddPhoneConfirmedAtToUsers < ActiveRecord::Migration
  def change
    add_column :users, :phone_confirmed_at, :datetime
  end
end
