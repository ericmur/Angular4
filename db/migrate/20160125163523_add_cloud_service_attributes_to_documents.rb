class AddCloudServiceAttributesToDocuments < ActiveRecord::Migration
  def change
    add_column :documents, :cloud_service_id, :integer
    add_column :documents, :cloud_service_path, :string
    add_column :documents, :cloud_service_revision, :integer
  end
end
