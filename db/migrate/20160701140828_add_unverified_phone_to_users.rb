class AddUnverifiedPhoneToUsers < ActiveRecord::Migration
  def change
    add_column :users, :unverified_phone, :string
  end
end
