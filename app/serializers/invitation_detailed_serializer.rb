class InvitationDetailedSerializer < ActiveModel::Serializer
  attributes :id, :accepted_at, :rejected_at, :accepted_by_user_id, :created_by_user_id
  attributes :email_invitation, :text_invitation, :created_at, :phone, :phone_normalized
  attributes :user, :state, :email, :invitee_type, :type, :uploaded_documents_count, :user_title, :group_user_labels

  delegate :current_user, to: :scope

  def user
    if object.created_by_user.advisor?
      AdvisorSerializer.new(object.created_by_user, { :scope => scope, :root => false })
    else
      UserSerializer.new(object.created_by_user, { :scope => scope, :root => false })
    end
  end

  def user_title
    if object.created_by_user.advisor?
      object.created_by_user.standard_category.name
    end
  end

  def uploaded_documents_count
    if !object.created_by_user.advisor?
      object.group_user ? object.group_user.document_ownerships.count : 0
    else
      client = Client.where(phone_normalized: object.phone_normalized).first
      client ? client.document_ownerships.count : 0
    end
  end

  def group_user_labels
    account_type_key = nil
    account_types = JSON.parse(ERB.new(File.read("#{Rails.root}/config/consumer_account_types.json.erb")).result)
    account_types.each do |key, val|
      next if current_user.consumer_account_type.nil?
      if val["id"] == current_user.consumer_account_type.id
        account_type_key = key
        break
      end
    end

    if account_type_key
      StandardGroup.default_label(StandardGroup::FAMILY, account_type_key)
    else #In case of registration while Account Type is not yet set, this else case is invoked
      []
    end
  end
end