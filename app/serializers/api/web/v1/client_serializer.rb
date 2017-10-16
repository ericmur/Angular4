class Api::Web::V1::ClientSerializer < ActiveModel::Serializer
  attributes :id, :advisor_id, :consumer_id, :user_id, :email, :documents_count, :all_documents_count,
             :unread_messages_count, :workflows_count, :chat_id, :parsed_fullname, :phone, :birthday,
             :phone_normalized, :group_users, :invitations_count, :sended_invitation_days_ago, :type,
             :invitation, :total_uploaded_docs_count, :last_message_in_client_chat,
             :employees_count, :contractors_count, :contacts_count, :consumer_created_at

  has_one :avatar

  def group_users
    return [] unless object.consumer_id

    ActiveModel::ArraySerializer.new(object.consumer.group_users_as_group_owner.where(label: [GroupUser::SPOUSE, GroupUser::KID]), each_serializer: ::Api::Web::V1::GroupUserSerializer)
  end

  def type
    object.class.to_s
  end

  def avatar
    object.consumer.avatar if object.consumer_id
  end

  #These are the count of total documents in the system for this user. This is used to show the count in Client Detail page when logged-in service provider is Docyt Support
  def total_uploaded_docs_count
    return 0 unless object.advisor.docyt_support?

    Api::Web::V1::DocumentsQuery.new(scope, { client_id: object.id }).get_all_uploaded_documents_count
  end

  #These are the count of documents owned by the contact of this client and shared with Advisor
  def documents_count
    Api::Web::V1::DocumentsQuery.new(scope, { contact_id: object.id, contact_type: object.class.to_s }).get_documents_count
  end

  #These are the count of documents of the client as well as the documents of their contacts that are shared with the service provider
  def all_documents_count
    Api::Web::V1::DocumentsQuery.new(scope, { client_id: object.id }).get_all_documents_count
  end

  def unread_messages_count
    return 0 unless object.consumer_id

    chat = Api::Web::V1::ChatsManager.new(scope, [object]).find_or_create_with_users
    chat.get_message_users(scope).count
  end

  def workflows_count
    # workflows not implemented now
    0
  end

  def chat_id
    return unless object.consumer_id

    chat = Api::Web::V1::ChatsManager.new(scope, [object]).find_or_create_with_users
    chat.id
  end

  def parsed_fullname
    if object.consumer_id
      name = object.consumer.parsed_fullname
      name.blank? ? object.consumer.phone_normalized : name
    else
      object.name ? object.name : (object.email ? object.email : object.phone_normalized)
    end
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

  def birthday
    object.owner_birthday
  end

  def invitation
    object.invitations.first if object.invitations
  end

  def employees_count
    object.employees_count(object.advisor)
  end

  def contractors_count
    object.contractors_count(object.advisor)
  end

  def contacts_count
    object.contacts_count(object.advisor)
  end

  def consumer_created_at
    object.consumer.created_at if object.consumer
  end
end
