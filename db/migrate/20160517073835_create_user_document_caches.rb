class CreateUserDocumentCaches < ActiveRecord::Migration
  def change
    create_table :user_document_caches do |t|
      t.references :user, index: true, foreign_key: true
      t.integer :version, index: true, default: 0
      t.text :encrypted_password_hash

      t.timestamps null: false
    end
  end
end
