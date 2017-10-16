class NotifyForwardedEmailProcessedJob < ActiveJob::Base
  queue_as :default

  def perform(doc_id)
    doc = Document.find(doc_id)
    
    notification = Notification.new
    notification.recipient = User.find(doc.uploader_id)
    notification.notifiable = doc

    if doc.standard_document.present?
      notification.message = "DocytBot received #{doc.original_file_name.truncate(30)} via email"
      notification.notification_type = Notification.notification_types[:document_update]
    else
      notification.message = "DocytBot received #{doc.original_file_name.truncate(30)} via email that needs your review."
      notification.notification_type = Notification.notification_types[:auto_categorization]
    end

    if notification.save
      notification.deliver([:push_notification])
    end
  end
end
