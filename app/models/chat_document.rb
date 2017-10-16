class ChatDocument < ActiveRecord::Base
  belongs_to :chat
  belongs_to :message, class: 'Messagable::Message'
  belongs_to :document

  validates :chat_id, :document_id, :message_id, presence: true
end
