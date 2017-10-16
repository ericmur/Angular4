class Workflow < ActiveRecord::Base
  include AASM

  belongs_to :admin, class_name: User.name.to_s #The service provider who created this workflow
  has_many   :workflow_standard_documents, as: :ownerable, dependent: :destroy
  has_many   :workflow_document_uploads, through: :workflow_standard_documents
  has_many   :participants, dependent: :destroy
  has_one    :chat, dependent: :destroy
  has_many   :messages, through: :chat

  validates :name, :admin_id, :end_date, :status, presence: true
  validates :status, inclusion: { in: %w(started ended) }

  after_save :create_chat_with_participants!

  aasm column: :status do
    state :started, initial: true
    state :ended

    event :ending  do
      transitions from: :started, to: :ended
    end
  end

  def participants_count
    participants.count
  end

  def unread_messages_count
    chat ? chat.get_message_users(admin).count : 0
  end

  def uploaded_documents_count
    workflow_document_uploads.count
  end

  def chat_id
    chat.id if chat
  end

  def count_of_categories_with_documents
    workflow_standard_documents
      .joins(:workflow_document_uploads)
      .group('workflow_standard_documents.id')
      .having("count(workflow_document_uploads.document_id) > ?", 0)
      .length
  end

  private

  def create_chat_with_participants!
    users_arr = participants.map { |participant| participant.user }

    Api::Web::V1::ChatsManager.new(admin, users_arr, { workflow_id: self.id }).find_or_create_with_users
  end

end
