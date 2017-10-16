class AddCloudServiceAuthToDocument < ActiveRecord::Migration
  def change
    remove_reference :documents, :cloud_service, :index => true
    add_reference :documents, :cloud_service_authorization, :index => true
  end
end
