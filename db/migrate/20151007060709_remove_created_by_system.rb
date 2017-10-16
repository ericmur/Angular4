class RemoveCreatedBySystem < ActiveRecord::Migration
  def change
    remove_column :symmetric_keys, :encrypted_by_system, :boolean, :default => false
    
    add_index :symmetric_keys, ["created_for_user_id", "document_id"], :name => "symmetric_keys_bi_index", :unique => true
  end
end
