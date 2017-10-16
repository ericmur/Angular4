class MessageSerializer < ActiveModel::Serializer
  attributes :id, :sender_id, :sender_type, :text, :created_at, :type, :user, :read_at, :document_id, :edited_at

  delegate :current_user, to: :scope

  def sender_type
    object.sender.advisor? ? "Advisor" : "User"
  end

  def read_at
    if scope and scope.class == Hash and scope[:user]
      u = scope[:user]
    else
      u = current_user
    end
    message_user = object.message_users.where(receiver_id: u.id).first
    message_user.read_at if message_user
  end

  def document_id
    object.chat_document.document_id if object.chat_document
  end

  def user
    UserSerializer.new(object.sender, { :root => false })
  end
end
