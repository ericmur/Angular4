class AddUniquessS3KeyMigration < ActiveRecord::Migration
  def change
    add_index :pages, :s3_object_key, :unique => true
  end
end
