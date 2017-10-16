class PullDocumentsByCloudServicePathJob < ActiveJob::Base
  queue_as :default

  def perform(cloud_service_path_id)
    cloud_service_path = CloudServicePath.find_by_id(cloud_service_path_id)
    cloud_service_name = cloud_service_path.cloud_service_authorization.cloud_service.name
    
    case cloud_service_name
    when CloudService::DROPBOX
      PullDocumentsFromDropboxService.new(cloud_service_path).call if cloud_service_path
    when CloudService::GOOGLE_DRIVE
      PullDocumentsFromGoogleDriveService.new(cloud_service_path).call if cloud_service_path
    end
  end
end
