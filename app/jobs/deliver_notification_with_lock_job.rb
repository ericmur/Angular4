class DeliverNotificationWithLockJob
  include Resque::Plugins::UniqueJob
  @queue = :default
  @lock_after_execution_period = 180

  def self.perform(document_id)
    notification_group = DocumentNotificationGroup.where(document_id: document_id).order(created_at: :desc).first
    if notification_group
      notification_group.invoke_notification_method
      DocumentNotificationGroup.where(document_id: notification_group.document_id).where(:created_at.lte => notification_group.created_at).destroy_all
    end
  end

end