class Api::Web::V1::MessageSerializer < ActiveModel::Serializer
  attributes :id, :chat_id, :sender_id, :text, :created_at, :sender_name

  has_one :chat_document, serializer: Api::Web::V1::ChatDocumentSerializer
  has_one :sender_avatar, serializer: Api::Web::V1::AvatarSerializer

  def chat_document
    object.chat_document.document if object.chat_document.present?
  end

  def sender_avatar
    object.sender.avatar if object.sender.avatar.present?
  end
end
