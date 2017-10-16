class Api::Web::V1::WorkflowSerializer < ActiveModel::Serializer
  attributes :id, :name, :end_date, :participants, :participants_count,
             :unread_messages_count, :status, :expected_documents_count,
             :uploaded_documents_count, :purpose, :count_of_categories_with_documents,
             :chat_id

  has_many :participants, serializer: Api::Web::V1::ParticipantSerializer
end
