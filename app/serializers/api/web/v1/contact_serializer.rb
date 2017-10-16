class Api::Web::V1::ContactSerializer < ActiveModel::Serializer
  attributes :id, :type, :user_id, :email, :documents_count, :parsed_fullname, :get_label,
             :get_structure_type, :avatar, :invitation, :invitation_sended_days_ago, :unread_messages_count,
             :chat_id, :phone, :phone_normalized, :employees_count, :contractors_count,
             :contacts_count, :all_documents_count

  def avatar
    return object.user.avatar if object.user_id

    object.avatar
  end

  def invitation
    return if object.class.name.to_s == Client.name.to_s

    object.invitation
  end

  def invitation_sended_days_ago
    return if object.class.name.to_s == Client.name.to_s

    if object.invitation && !object.invitation.accepted_at
      (Time.now.to_date - invitation.created_at.to_date).to_i
    end
  end

  def type
    object.class.to_s
  end

  def user_id
    object.user_id
  end

  def email
    object.owner_email
  end

  def phone
    object.owner_phone
  end

  def phone_normalized
    object.owner_phone_normalized
  end

  def documents_count
    Api::Web::V1::DocumentsQuery.new(scope, { contact_id: object.id, contact_type: object.class.to_s }).get_documents_count
  end

  def all_documents_count
    Api::Web::V1::DocumentsQuery.new(scope, { contact_id: object.id, contact_type: object.class.to_s }).get_all_documents_count
  end

  def parsed_fullname
    return object.user.parsed_fullname if object.user_id

    object.name
  end

  def get_structure_type
    object.structure_type if object.respond_to?(:structure_type)
  end

  def get_label
    if object.class == GroupUser
      object.label
    elsif object.class == Client
      'Client'
    else
      raise "Invalid type: #{object.class.to_s}"
    end
  end

  def unread_messages_count
    return 0 unless object.user_id

    chat = Api::Web::V1::ChatsManager.new(scope, [object.user]).find_or_create_with_users
    chat.get_message_users(scope).count
  end

  def chat_id
    return unless object.user_id

    chat = Api::Web::V1::ChatsManager.new(scope, [object.user]).find_or_create_with_users
    chat.id
  end

  def employees_count
    object.employees_count(scope)
  end

  def contractors_count
    object.contractors_count(scope)
  end

  def contacts_count
    object.contacts_count(scope)
  end
end
