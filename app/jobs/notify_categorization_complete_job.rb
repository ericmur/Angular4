class NotifyCategorizationCompleteJob < ActiveJob::Base
  queue_as :default

  def perform(cloud_service_path_id)
    cloud_service_path = CloudServicePath.find_by_id(cloud_service_path_id)
    cloud_service_name = cloud_service_path.cloud_service_authorization.cloud_service.name
    
    n_docs = cloud_service_path.cloud_service_authorization.user.suggested_documents_for_upload.count
    notification = Notification.new
    notification.recipient = User.find(cloud_service_path.cloud_service_authorization.user_id)
    notification.message = "DocytBot has found #{n_docs} documents that need your review."
    notification.notification_type = Notification.notification_types[:auto_categorization]
    if notification.save
      notification.deliver([:push_notification])
    end
  end
end
