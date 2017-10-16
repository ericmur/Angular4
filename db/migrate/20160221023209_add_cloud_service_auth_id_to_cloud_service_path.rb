class AddCloudServiceAuthIdToCloudServicePath < ActiveRecord::Migration
  def change
    remove_reference :cloud_service_paths, :cloud_service, :index => true
    add_reference :cloud_service_paths, :cloud_service_authorization, :index => true
  end
end
