module Invitationable
  class AdvisorToConsumerInvitation < Invitation
    INVITATION_TYPE = to_s.demodulize

    belongs_to :client

    def accept_invitation!(user, invitation_source=nil)
      ActiveRecord::Base.transaction do
        begin
          self.accepted_by_user_id = user.id
          if user.first_name.blank?
            user.parse_fullname(self.client.name)
            user.save!
          end

          if self.email.present?
            set_user_email_from_invitation(user, invitation_source)
          end

          consumer = User.find_by(phone_normalized: user.phone_normalized)
          set_consumer_id(consumer.id) if consumer

          accept!
        rescue => e
          self.errors[:base] << e.message
          raise ActiveRecord::Rollback
        end
      end

      if self.errors.empty?
        DocumentCacheService.update_cache([:standard_folder, :standard_document, :document, :folder_setting], [accepted_by_user.id])
      end

      return self.errors.empty?
    end

    def generate_notification_for_accepted_invitation!
      notification = Notification.new
      notification.sender = self.accepted_by_user
      notification.recipient = self.created_by_user
      notification.message = "#{self.accepted_by_user.first_name} has accepted your invitation and you are now connected."
      notification.notifiable = self
      notification.notification_type = Notification.notification_types[:invitation_accepted]
      if notification.save!
        notification.deliver([:push_notification])
      end
    end

    private

    def set_consumer_id(consumer_id)
      self.client.consumer_id = consumer_id
      self.client.save
    end
  end
end
