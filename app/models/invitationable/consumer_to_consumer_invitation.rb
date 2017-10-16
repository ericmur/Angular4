module Invitationable
  class ConsumerToConsumerInvitation < Invitation
    INVITATION_TYPE = to_s.demodulize

    belongs_to :group_user

    validates :group_user_id, uniqueness: { scope: :created_by_user_id }, :allow_blank => true

    after_create :update_group_user_email_and_phone

    def accept_invitation!(user, group_user_id=nil, group_user_label=nil, invitation_source=nil)
      ActiveRecord::Base.transaction do 
        begin
          should_generate_folder_setting = true
          invitee_group_user = nil

          if group_user_id.present?
            should_generate_folder_setting = false
            invitee_group_user = user.group_users_as_group_owner.where(id: group_user_id).first
          elsif group_user_label.present?
            invitee_group_user = build_group_user_for_invitee(user, group_user_label)
          end

          raise "Require group user or label" if invitee_group_user.blank?

          self.accepted_by_user_id = user.id
          if user.first_name.blank?
            user.parse_fullname(self.group_user.name)
            user.save!
          end
          if self.email.present? 
            set_user_email_from_invitation(user, invitation_source)  
          end
          self.group_user.set_user_without_transaction(self.accepted_by_user_id)
          invitee_group_user.save!
          invitee_group_user.set_user_without_transaction(self.created_by_user_id)
          accept!

          invitee_group_user.invitation.destroy if invitee_group_user.invitation

          invitee_group_user.generate_folder_settings(user, group_user_label) if should_generate_folder_setting
        rescue => e
          self.errors[:base] << e.message
          raise ActiveRecord::Rollback
        end
      end

      if self.errors.empty?
        # Copy avatar from group_user to user
        # Invoke here so copy operation doesn't rollback invitation
        self.group_user.copy_avatar_to_user

        DocumentCacheService.update_cache([:standard_folder, :standard_document, :document, :folder_setting], [created_by_user_id, accepted_by_user_id])
      end

      return self.errors.empty?
    end

    def generate_notification_for_accepted_invitation!
      notification                   = Notification.new
      notification.sender            = self.accepted_by_user
      notification.recipient         = self.created_by_user
      inviter_group_user             = self.created_by_user.groups_as_owner.first.group_users.where(user_id: self.accepted_by_user.id).first
      notification.message           = "#{self.accepted_by_user.first_name} has accepted your invitation and you are now connected."
      notification.notifiable        = inviter_group_user
      notification.notification_type = Notification.notification_types[:invitation_accepted]
      if notification.save!
        notification.deliver([:push_notification])
      end
    end

    def build_group_user_for_invitee(user, group_user_label)
      invitee_group_user         = GroupUser.new
      invitee_group_user.name    = self.created_by_user.name
      invitee_group_user.email   = self.email
      invitee_group_user.phone   = self.phone
      invitee_group_user.user_id = self.created_by_user_id
      invitee_group_user.group   = user.groups_as_owner.first
      invitee_group_user.label   = group_user_label

      return invitee_group_user
    end

    def update_group_user_email_and_phone
      if self.group_user.present?
        group_user.email       = self.email
        group_user.phone       = self.phone
        group_user.unlinked_at = nil
        group_user.save!
      end
    end
  end
end
