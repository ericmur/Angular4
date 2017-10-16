class AddCloudServicePathReferenceToDocument < ActiveRecord::Migration
  def change
    add_reference :documents, :cloud_service_path, :index => true
    remove_column :documents, :cloud_service_path, :string
    add_column :documents, :cloud_service_full_path, :string
  end
end
