class ModifySymmetricKeyIndex < ActiveRecord::Migration
  def change
    add_index :symmetric_keys, :document_id, :where => "created_for_user_id is null", :unique => true
  end
end
