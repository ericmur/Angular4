class CreateStandardBaseDocument < ActiveRecord::Migration
  def change
    create_table :standard_base_documents do |t|
      t.string :name
      t.string :type
      t.boolean :category
      t.integer :rank
    end
    
    execute(%q{
      ALTER SEQUENCE standard_base_documents_id_seq RESTART WITH 10001
    }) #Assuming we will have a maximum of 1000 standard_base_documents to manage. Beyond that will be consumer provided standard_base_documents
    
    add_index :standard_base_documents, :id, :unique => true
  end
end
