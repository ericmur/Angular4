class AddAccountTypeFieldIntoConsumer < ActiveRecord::Migration
  def change
    remove_column :users, :account_type, :string
    add_reference :users, :consumer_account_type
  end
end
