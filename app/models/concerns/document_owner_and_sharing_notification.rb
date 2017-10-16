require 'active_support/concern'

module DocumentOwnerAndSharingNotification
  extend ActiveSupport::Concern

  def businesses_names
    business_documents.map{ |d| d.business.name }.flatten.uniq
  end

  def notify_new_users(current_user, new_owner_ids)
    new_owner_ids.each do |recipient_id|
      notify_new_document_owner(current_user, recipient_id)
    end
  end

  def notify_new_document_owner(current_user, recipient_id)
    return if recipient_id == current_user.id
    notification = Notification.new
    notification.sender = User.find(current_user.id)
    notification.recipient = User.find(recipient_id)
    if businesses_names.empty?
      notification.message = "#{current_user.first_name} has added you as an owner of a document: #{self.standard_document.name}"
    else
      notification.message = "#{current_user.first_name} has added you as an owner of #{self.standard_document.name} for #{businesses_names.join(', ')}"
    end
    notification.notifiable = self
    notification.notification_type = Notification.notification_types[:new_document_sharing]
    if notification.save!
      notification.deliver([:push_notification])
    end
  end

  def create_notification_for_owners
    return if uploader.blank?
    return if self.standard_document_id.nil? #E.g. discovered documents or the ones being uploaded by service provider but not categorized yet
    document_owners.only_connected_owners.each do |document_owner|
      next if document_owner.owner_id == self.uploader_id

      unless self.symmetric_keys.for_user_access(document_owner.owner_id).select("1").first.nil?
        notification = Notification.new
        notification.sender = self.uploader
        notification.recipient = User.find(document_owner.owner_id)
        notification.message = "#{self.uploader.first_name} has uploaded #{self.standard_document.name} for you."
        notification.notifiable = self
        notification.notification_type = Notification.notification_types[:new_document_sharing]
        if notification.save!
          notification.deliver([:push_notification])
        end
      end
    end
  end

  def notify_deleted_owner(current_user, recipient_id)
    return if recipient_id == current_user.id
    notification = Notification.new
    notification.sender = User.find(current_user.id)
    notification.recipient = User.find(recipient_id)
    notification.message = "#{current_user.first_name} has removed you as an owner of a document: #{self.standard_document.name}"
    notification.notifiable = self
    notification.notification_type = Notification.notification_types[:revoked_document_owner]
    if notification.save!
      notification.deliver([:push_notification])
    end
  end

  def notify_deleted_owners(current_user, deleted_owners)
    deleted_owners.each do |recipient_id|
      notify_deleted_owner(current_user, recipient_id)
    end
  end

  def notify_new_document_sharing(current_user, recipient_id)
    return if recipient_id == current_user.id
    notification = Notification.new
    notification.sender = User.find(current_user.id)
    notification.recipient = User.find(recipient_id)
    notification.message = "#{current_user.first_name} has shared #{self.standard_document.name} with you."
    notification.notifiable = self
    notification.notification_type = Notification.notification_types[:new_document_sharing]
    if notification.save!
      notification.deliver([:push_notification])
    end
  end

  def notify_revoked_document_sharing(current_user, recipient_id)
    return if recipient_id == current_user.id
    notification = Notification.new
    notification.sender = User.find(current_user.id)
    notification.recipient = User.find(recipient_id)
    doc_owner = self.document_owners.first
    if doc_owner && doc_owner.owner_name.present?
      notification.message = "#{current_user.first_name} has revoked access to #{doc_owner.owner_name}'s #{self.standard_document.name}."
    else
      notification.message = "#{current_user.first_name} has revoked access to #{self.standard_document.name}."
    end
    notification.notifiable = self
    notification.notification_type = Notification.notification_types[:revoked_document_sharing]
    if notification.save!
      notification.deliver([:push_notification])
    end
  end

  def notify_old_owners_for_new_owners(current_user, old_owner_ids)
    old_owner_ids.each do |old_owner_id|
      next if old_owner_id == current_user.id
      notification = Notification.new
      notification.sender = User.find(current_user.id)
      notification.recipient = User.find(old_owner_id)
      notification.message = "#{current_user.first_name} has added a new owner to your document: #{self.standard_document.name}"
      notification.notifiable = self
      notification.notification_type = Notification.notification_types[:document_update]
      if notification.save!
        notification.deliver([:push_notification])
      end
    end
  end

end