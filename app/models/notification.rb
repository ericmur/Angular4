class Notification < ActiveRecord::Base
  DELIVERY_METHODS = %w[push_notification email text]
  enum notification_type: [ :document_expiring,
                            :auto_categorization,
                            :invitation_created,
                            :invitation_accepted,
                            :invitation_rejected,
                            :unlinked_group_user,
                            :new_document_sharing,
                            :revoked_document_sharing,
                            :document_update,
                            :revoked_document_owner,
                            :document_access_requested,
                            :document_access_granted,
                            :new_mobile_app_update,  # since 1.1.5
                            :fax_updated, # since 1.2.0
                            :business_updated ] # since 1.2.1

  belongs_to :sender, class_name: 'User'
  belongs_to :recipient, class_name: 'User'
  belongs_to :notifiable, polymorphic: true

  validates :recipient_id, presence: true
  validates :message, presence: true
  validates :notification_type, presence: true
  validate  :associated_notifiable

  scope :unread, -> { where(unread: true) }
  scope :read, -> { where(unread: false) }

  after_create :cleanup_recipient_notifications

  def deliver(couriers=[], options={})
    if notification_type == "document_expiring" && notifiable == nil
      raise "Notifiable object has been deleted."
    end

    couriers.map(&:to_s).each do |courier|
      next unless DELIVERY_METHODS.include?(courier)
      case courier
      when 'push_notification'
        DeliverPushNotificationJob.perform_later(self.id)
      when 'email'
        deliver_email_notification(options)
      when 'text'
        deliver_text_notification
      end
    end
  end

  def mark_as_read
    self.update_column(:unread, false)
  end

  def deliver_push_notification
    content = NotificationSerializer.new(self, { :root => false }).serializable_hash
    PushDevice.where(:user_id => recipient_id).each do |device|
      device.push(message, { "type" => notification_type, "content" => content })
    end
  end

  def deliver_email_notification(options={})
    if notification_type == "document_expiring"
      field_value_id = options[:field_value_id]
      notify_duration_id = options[:notify_duration_id]
      UserMailer.expiring_document(recipient.id, notifiable.id, field_value_id, notify_duration_id).deliver_later
    end
  end

  def deliver_text_notification
    # placeholder for text notification
  end

  private

  def cleanup_recipient_notifications
    CleanupUserNotificationsJob.perform_later(recipient_id)
  end

  def associated_notifiable
    if notification_type == "document_expiring" && self.notifiable.class.to_s != "Document"
      self.errors[:base] << I18n.t('errors.notification.require_document')
    elsif notification_type == "invitation" && self.notifiable.class.to_s != "Invitation"
      self.errors[:base] << I18n.t('errors.notification.require_invitation')
    end
  end


end
