class CreateDocumentAccessRequests < ActiveRecord::Migration
  def change
    create_table :document_access_requests do |t|
      t.references :document, index: true, foreign_key: true
      t.integer :created_by_user_id
      t.integer :uploader_id

      t.timestamps null: false
    end
  end
end
