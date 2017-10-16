class CreatePage < ActiveRecord::Migration
  def change
    create_table :pages do |t|
      t.integer :document_id
      t.string  :s3_object_key
      t.string  :name
      t.integer :page_num
      t.string  :state
    end
  end
end
