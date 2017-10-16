class CreateSymmetricKeys < ActiveRecord::Migration
  def change
    create_table :symmetric_keys do |t|
      t.integer   :created_for_user_id
      t.integer   :created_by_user_id
      t.text      :key_encrypted
      t.integer   :document_id
      t.boolean   :encrypted_by_system, :default => false
      t.timestamps
    end

    add_index :symmetric_keys, [:created_for_user_id, :document_id, :encrypted_by_system], :unique => true, :name => "symmetric_keys_tri_index"
  end
end
