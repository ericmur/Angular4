class AddPathDisplayNameToCloudServicePath < ActiveRecord::Migration
  def change
    add_column :cloud_service_paths, :path_display_name, :string
  end
end
