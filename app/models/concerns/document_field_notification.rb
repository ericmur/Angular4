require 'active_support/concern'

module DocumentFieldNotification
  extend ActiveSupport::Concern

  def enqueue_generate_notification_for_updated_value(current_user, field)
    n = DocumentNotificationGroup.new
    n.user = current_user
    n.document = self
    n.method_name = 'generate_notification_for_updated_value'
    n.notification_object = field.name
    n.save
    Resque.enqueue DeliverNotificationWithLockJob, self.id
  end

  def enqueue_generate_notification_for_new_field(current_user, field)
    n = DocumentNotificationGroup.new
    n.user = current_user
    n.document = self
    n.method_name = 'generate_notification_for_new_field'
    n.notification_object = field.name
    n.save
    Resque.enqueue DeliverNotificationWithLockJob, self.id
  end

  def enqueue_generate_notification_for_deleted_field(current_user, field)
    n = DocumentNotificationGroup.new
    n.user = current_user
    n.document = self
    n.method_name = 'generate_notification_for_deleted_field'
    n.notification_object = field.name
    n.save
    Resque.enqueue DeliverNotificationWithLockJob, self.id
  end

  def enqueue_create_notification_for_completed_page(current_user, page)
    n = DocumentNotificationGroup.new
    n.user = current_user
    n.document = self
    n.method_name = 'generate_notification_for_document_page'
    n.notification_object = page
    n.save
    Resque.enqueue DeliverNotificationWithLockJob, self.id
  end

  def enqueue_create_notification_for_deleted_page(current_user)
    n = DocumentNotificationGroup.new
    n.user = current_user
    n.document = self
    n.method_name = 'generate_notification_for_deleted_page'
    n.save
    Resque.enqueue DeliverNotificationWithLockJob, self.id
  end

  def generate_notification_for_updated_value(current_user, field_name)
    deliver_notification_for_updated_value(current_user, field_name)
  end

  def generate_notification_for_new_field(current_user, field_name)
    deliver_notification_for_new_field(current_user, field_name)
  end

  def generate_notification_for_deleted_field(current_user, field_name)
    deliver_notification_for_deleted_field(current_user, field_name)
  end

  def generate_notification_for_document_page(current_user, page)
    page.create_notification_for_completed_page!(current_user)
  end

  def generate_notification_for_deleted_page(current_user, options=nil)
    deliver_notification_for_deleted_page(current_user)
  end

  private

  def deliver_notification_for_updated_value(current_user, field_name)
    sharee_list = self.symmetric_keys.where.not(created_for_user_id: current_user.id).map(&:created_for_user_id)
    sharee_list.uniq.each do |recipient_id|
      next if current_user.id == recipient_id
      notification = Notification.new
      notification.sender = User.find_by_id(current_user.id)
      notification.recipient = User.find_by_id(recipient_id)
      notification.message = "#{current_user.first_name} has updated the field: #{field_name} in the document: #{self.standard_document.name}"
      notification.notifiable = self
      notification.notification_type = Notification.notification_types[:document_update]
      if notification.save
        notification.deliver([:push_notification])
      end
    end
  end

  def deliver_notification_for_new_field(current_user, field_name)
    sharee_list = self.symmetric_keys.where.not(created_for_user_id: current_user.id).map(&:created_for_user_id)
    sharee_list.uniq.each do |recipient_id|
      next if recipient_id == current_user.id
      notification = Notification.new
      notification.sender = User.find_by_id(current_user.id)
      notification.recipient = User.find_by_id(recipient_id)
      notification.message = "#{current_user.first_name} has added a new field: #{field_name} in the document: #{self.standard_document.name}"
      notification.notifiable = self
      notification.notification_type = Notification.notification_types[:document_update]
      if notification.save
        notification.deliver([:push_notification])
      end
    end
  end

  def deliver_notification_for_deleted_field(current_user, field_name)
    sharee_list = self.symmetric_keys.where.not(created_for_user_id: current_user.id).map(&:created_for_user_id)
    sharee_list.uniq.each do |recipient_id|
      next if recipient_id == current_user.id
      notification = Notification.new
      notification.sender = User.find_by_id(current_user.id)
      notification.recipient = User.find_by_id(recipient_id)
      notification.message = "#{current_user.first_name} has removed the field: #{field_name} from the document: #{self.standard_document.name}"
      notification.notifiable = self
      notification.notification_type = Notification.notification_types[:document_update]
      if notification.save
        notification.deliver([:push_notification])
      end
    end
  end

  def deliver_notification_for_deleted_page(current_user)
    sharee_list = self.symmetric_keys.where.not(created_for_user_id: current_user.id).map(&:created_for_user_id)
    sharee_list.uniq.each do |recipient_id|
      next if recipient_id == current_user.id
      notification = Notification.new
      notification.sender = User.find_by_id(current_user.id)
      notification.recipient = User.find_by_id(recipient_id)
      notification.message = "#{current_user.first_name} has deleted a page from the document: #{self.standard_document.name}"
      notification.notifiable = self
      notification.notification_type = Notification.notification_types[:document_update]
      if notification.save
        notification.deliver([:push_notification])
      end
    end
  end

end