class AddUnconfirmedEmailToUsers < ActiveRecord::Migration
  def change
    add_column :users, :unverified_email, :string
  end
end
