module Invitationable
  require 'token_utils'
  require 'aasm'

  class Invitation < ActiveRecord::Base
    SOURCE = { :email => "email", :text => "text" }
    INVITATION_TYPES = %w(
                          Invitationable::ConsumerToConsumerInvitation
                          Invitationable::AdvisorToConsumerInvitation
                         )

    include TokenUtils
    include AASM

    belongs_to :accepted_by_user, class_name: 'User', foreign_key: 'accepted_by_user_id'
    belongs_to :created_by_user, class_name: 'User', foreign_key: 'created_by_user_id'
    belongs_to :rejected_by_user, class_name: 'User', foreign_key: 'accepted_by_user_id'

    validates :phone, presence: true, if: Proc.new { |invitation| invitation.text_invitation? }
    validates :email, presence: true, if: Proc.new { |invitation| invitation.email_invitation? }
    validates :created_by_user_id, presence: true
    validate :already_sended_to_phone_number, if: Proc.new { |invitation| invitation.text_invitation? }, on: :create
    validate :already_sended_to_email, if: Proc.new { |invitation| invitation.email_invitation? }, on: :create
    validate :require_invitation_type
    validate :require_inviter_name
    validate :require_same_phone_number, if: Proc.new { |d| d.accepted_by_user.present? }
    validates_plausible_phone :phone, :normalized_country_code => 'US'
    validates :invitee_type, inclusion: { in: %w(Consumer Advisor), message: "%{value} is not a valid account type" }
    validates :type, presence: true, inclusion: { in: INVITATION_TYPES }

    phony_normalize :phone, :as => :phone_normalized, :default_country_code => 'US'

    after_create :create_invitation_token, :unless => Proc.new { |d| d.accepted_at }
    after_create :process_invitation

    aasm column: :state do
      state :pending, :initial => true
      state :rejected
      state :accepted

      event :reject, after: [:set_rejected_date_and_notify, :clear_token] do
        transitions from: [:pending], to: :rejected, guard: :has_rejecting_user?
      end

      event :accept, after: [:process_accepted_invitation, :clear_token] do
        transitions from: [:pending], to: :accepted, guard: [:has_accepting_user?, :invitee_has_same_phone?]
      end
    end

    def process_invitation
      existing_user = User.where(phone_normalized: self.phone_normalized).first
      generate_notification_for_created_invitation(existing_user, true) if existing_user

      enqueue_email_invitation if email_invitation
      enqueue_text_invitation if text_invitation
    end

    def deliver_text_invitation
      return if token.blank?

      unless ENV['WORK_OFFLINE']
        url = Rails.application.routes.url_helpers.preview_invitation_url(token: self.token, source: SOURCE[:text], host: ENV['SMTP_DOMAIN'], protocol: 'https')

        connect_msg = if invitation_to_existing_user?
                        if self.text_content
                          self.text_content
                        else
                          "#{self.created_by_user.first_name} has invited you to connect on Docyt"
                        end
                      else
                        "#{self.created_by_user.first_name} has invited you to join Docyt"
                      end

        message = "#{connect_msg}.\n\nTo open Docyt click here: #{url}"
        TwilioClient.get_instance.account.messages.create({
          :from => TwilioClient.phone_number,
          :to => self.phone_normalized,
          :body => message
        })
      end
    end

    def generate_notification_for_created_invitation(user, deliver_push_notification=false)
      notification = Notification.new
      notification.sender = self.created_by_user
      notification.recipient = user
      notification.message = "#{self.created_by_user.first_name} has invited you to connect on Docyt"
      notification.notifiable = self
      notification.notification_type = Notification.notification_types[:invitation_created]
      if notification.save!
        notification.deliver([:push_notification]) if deliver_push_notification
      end
    end

    def generate_notification_for_rejected_invitation!
      notification = Notification.new
      notification.sender = self.rejected_by_user
      notification.recipient = self.created_by_user
      notification.message = "#{self.rejected_by_user.first_name} has declined your invitation."
      notification.notifiable = self
      notification.notification_type = Notification.notification_types[:invitation_rejected]
      if notification.save!
        notification.deliver([:push_notification])
      end
    end

    def set_user_email_from_invitation(user, invitation_source)
      if user.email.blank?
        user.email = self.email
        if invitation_source == SOURCE[:email]
          user.confirm_email
        else
          user.save!
        end
      elsif !user.email_confirmed? && invitation_source == SOURCE[:email] && user.email == self.email
        user.confirm_email
      end
    end

    def invitation_to_existing_user?
      User.where(phone_normalized: self.phone_normalized).exists?
    end

    def invitation_type
      self.class.to_s.demodulize
    end

    def resend
      return if accepted?
      create_invitation_token
      process_invitation
    end

    private

    def clear_token
      Invitationable::Invitation.where(id: self.id).update_all(token: nil)
    end

    def enqueue_email_invitation
      InvitationMailer.invitation_email(self.id, self.token).deliver_later
    end

    def enqueue_text_invitation
      TextInvitationJob.perform_later(self.id)
    end

    def process_accepted_invitation
      update_column(:accepted_at, Time.zone.now)
      generate_notification_for_accepted_invitation!
    end

    def set_rejected_date_and_notify
      update_column(:rejected_at, Time.zone.now)
      generate_notification_for_rejected_invitation!
    end

    def has_accepting_user?
      self.accepted_by_user.present?
    end

    def has_rejecting_user?
      self.rejected_by_user.present?
    end

    def invitee_has_same_phone?
      self.phone_normalized == self.accepted_by_user.phone_normalized
    end

    def require_inviter_name
      unless created_by_user.has_fullname?
        self.errors[:base] << I18n.t('errors.invitation.require_fullname')
      end
    end

    def require_invitation_type
      if text_invitation? == false && email_invitation? == false
        self.errors[:base] << I18n.t('errors.invitation.require_type_selection')
      end
    end

    def require_same_phone_number
      unless invitee_has_same_phone?
        self.errors[:base] << I18n.t('errors.invitation.require_same_phone_number')
      end
    end

    def already_sended_to_email
      if Invitationable::Invitation.find_by(email: self.email, :created_by_user_id => self.created_by_user_id, :state => 'pending').present?
        self.errors[:base] << I18n.t('errors.invitation.already_sended_to_email')
      end
    end

    def already_sended_to_phone_number
      if Invitationable::Invitation.find_by(phone: self.phone, :created_by_user_id => self.created_by_user_id, :state => 'pending').present?
        self.errors[:base] << I18n.t('errors.invitation.already_sended_to_phone_number')
      end
    end

    def create_invitation_token
      generate_unique_token_for_field('token')
    end
  end
end
