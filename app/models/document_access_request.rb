class DocumentAccessRequest < ActiveRecord::Base
  belongs_to :document
  # uploader is the person that will give the access.
  belongs_to :uploader, class_name: 'User', foreign_key: 'uploader_id'
  # created_by_user is the person that need the access to document.
  belongs_to :created_by_user, class_name: 'User', foreign_key: 'created_by_user_id'

  validates :document_id, :uploader_id, :created_by_user_id, presence: true

  scope :created_by, -> (user_id) { where(created_by_user_id: user_id) }
  scope :uploaded_by, -> (user_id) { where(uploader_id: user_id) }
  scope :for_document, -> (document_id) { where(document_id: document_id) }

  def description
    standard_document = document.standard_document
    standard_folder = standard_document.standard_folder_standard_documents.first.standard_folder
    "#{standard_folder.name} / #{standard_document.name}"
  end

  def self.process_access_request_for_user(current_user, user)
    access_requests = created_by(user.id).uploaded_by(current_user.id)
    access_requests_count = 0
    access_requests.each do |access_request|
      if access_request.build_symmetric_key
        access_request.destroy
        access_requests_count += 1
      end
    end
    if access_requests_count > 0
      send_processed_request_notification(current_user, user)
      DocumentCacheService.update_cache([:document], [user.id])
    end
    access_requests_count
  end

  def self.send_processed_request_notification(current_user, user)
    notification = Notification.new
    notification.sender = current_user
    notification.recipient = user
    notification.message = "#{current_user.first_name} has given access to the documents uploaded for you"
    notification.notifiable = nil
    notification.notification_type = Notification.notification_types[:document_access_granted]
    if notification.save
      notification.deliver([:push_notification])
    end
  end

  def send_request_notification
    notification = Notification.new
    notification.sender = created_by_user
    notification.recipient = uploader
    notification.message = "#{created_by_user.first_name} is requesting document access"
    notification.notifiable = created_by_user
    notification.notification_type = Notification.notification_types[:document_access_requested]
    if notification.save
      notification.deliver([:push_notification])
    end
  end

  def build_symmetric_key
    unless document.accessible_by_me?(created_by_user)
      user_key = document.build_symmetric_key_for_user(:by_user_id => self.uploader_id, :with_user_id => self.created_by_user_id)
      user_key.save
    end
  end
end
