class CreateBusinessDocuments < ActiveRecord::Migration
  def change
    create_table :business_documents do |t|
      t.references :business, index: true, foreign_key: true
      t.references :document, index: true, foreign_key: true

      t.timestamps null: false
    end
  end
end
