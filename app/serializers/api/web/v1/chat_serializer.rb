class Api::Web::V1::ChatSerializer < ActiveModel::Serializer
  attributes :id, :unread_messages_count, :last_message_created_at

  has_many :chat_members, serializer: Api::Web::V1::ChatMemberSerializer

  def chat_members
    object.chat_members(scope)
  end

  def unread_messages_count
    object.get_message_users(scope).size
  end

  def last_message_created_at
    object.messages.last.created_at if object.messages.any?
  end
end
