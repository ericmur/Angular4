class ConsumerFolderAccountTypeUniqueIndex < ActiveRecord::Migration
  def change
    add_index :consumer_folder_account_types, [:standard_folder_id, :consumer_account_type_id], :unique => true, :name => "consumer_folder_acc_types_uni_index"
  end
end
