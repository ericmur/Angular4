class AdvisorSerializer < ActiveModel::Serializer
  attributes :id, :email, :phone, :phone_normalized, :first_name, :last_name, :middle_name, :avatar
  attributes :standard_category_id, :type, :standard_category_name, :messages_count, :documents_count, :standard_category_id
  attributes :shared_group_users_ids

  delegate :current_user, to: :scope

  def standard_category_name
    object.standard_category.name
  end

  def standard_category_id
    object.standard_category_id
  end

  # unread message count
  def messages_count
    chat = Api::Web::V1::ChatsManager.new(object, [user_from_scope]).find_or_create_with_users
    chat.get_message_users([user_from_scope]).count
  end

  def documents_count
    if client = object.clients_as_advisor.where(consumer_id: user_from_scope.id).first
      Document.where(id: Api::Web::V1::DocumentsQuery.new(object, { client_id: client.id }).get_all_documents_ids).where.not(:standard_document_id => nil).count
    else
      return 0
    end
  end

  def shared_group_users_ids
    group_user_ids = user_from_scope.group_users_as_group_owner.select('id').map(&:id)
    object.group_users.where(id: group_user_ids).select('id').map(&:id)
  end

  def avatar
    AvatarSerializer.new(object.avatar, { :scope => scope, :root => false })
  end

  def type
    'Advisor'
  end

  private
  def user_from_scope
    if scope.class == Hash && scope[:user]
      scope[:user] #We pass in scope as a hash containing current_user from ConsumerSerializer during users#create call. In this call, there is no current_user, hence we have to pass it in this manner
    else
      current_user
    end
  end
end
