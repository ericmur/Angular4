class CreateSymmetricKeyArchives < ActiveRecord::Migration
  def change
    create_table :symmetric_key_archives do |t|
      t.integer :created_for_user_id
      t.integer :created_by_user_id
      t.integer :document_id
      t.datetime :symmetric_key_created_at
      t.timestamps
    end
  end
end
