class AddModifiedAtToDocument < ActiveRecord::Migration
  def change
    add_column :documents, :cloud_service_last_modified_at, :string
    add_column :documents, :last_modified_at, :datetime
  end
end
