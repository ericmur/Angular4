module Messagable

  class Message < ActiveRecord::Base
    MESSAGE_TYPES = %w(
                       Messagable::WebMessage
                       Messagable::EmailMessage
                       Messagable::SmsMessage
                      )

    belongs_to :sender, class_name: 'User'
    belongs_to :chat
    has_many   :message_users, :dependent => :destroy
    has_one    :chat_document, :dependent => :destroy

    validates :text,   presence: true
    validates :sender, presence: true
    validates :chat,   presence: true
    validates :type,   presence: true, inclusion: { in: MESSAGE_TYPES }

    scope :unread_for_receiver, -> (user) {
      joins(:message_users).where(message_users: { receiver: user, read_at: nil } )
    }

    def create_notifications_for_chat_users!
      self.chat.chatable_users.where.not(id: self.sender_id).each do |chatable_user|
        self.message_users.create!(receiver: chatable_user)
      end
    end

    def sender_name
      self.sender.parsed_fullname || self.sender.email || self.sender.phone_normalized
    end

  end
end
