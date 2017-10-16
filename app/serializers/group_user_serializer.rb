class GroupUserSerializer < ActiveModel::Serializer
  attributes :id, :name, :phone, :email, :label, :avatar, :profile_background, :structure_type, :invitation, :folder_settings, :business_id
  attributes :number_of_documents, :number_of_expiring_documents, :user, :unlinked_at, :user_folder_settings, :consumer_account_type_id

  # not sure why but adding new attributes to invitation, make has_one failed to render the correct serializer
  def invitation
    InvitationSerializer.new(object.invitation, { :scope => scope, :root => false })
  end

  def consumer_account_type_id
    if object.user
      object.user.consumer_account_type_id
    else
      nil
    end
  end
  
  def user
    UserSerializer.new(object.user, { :scope => scope, :root => false })
  end

  def object_user
    self.object.user
  end

  def name
    object_user.present? ? object_user.name : object.name
  end

  def phone
    object_user.present? ? object_user.phone : object.phone
  end

  def phone_normalized
    object_user.present? ? object_user.phone_normalized : object.phone_normalized
  end

  def email
    object_user.present? ? object_user.email : object.email
  end

  def avatar
    AvatarSerializer.new(object.avatar, { :scope => scope, :root => false })
  end

  def number_of_documents
    object.number_of_documents
  end

  def number_of_expiring_documents
    object.number_of_expiring_documents
  end

  # New UserFolderSettingFormat
  # Since: 1.1.7
  def folder_settings
    ActiveModel::ArraySerializer.new(object.user_folder_settings,
      root: false,
      each_serializer: Api::Mobile::V2::UserFolderSettingSerializer,
      scope: scope
    )
  end

  # Backward compatibilty
  def user_folder_settings
   object.user_folder_settings.displayed.order(folder_owner_id: :asc).group_by{ |d| d.folder_owner_identifier }.map{ |k,v| [k, v.map(&:standard_base_document_id)] }.to_h
  end
end
