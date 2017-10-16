class Api::Mobile::V2::ClientSerializer < ActiveModel::Serializer
  attributes :id, :name, :email, :phone, :phone_normalized, :consumer_id, :user, :invitation
  attributes :folder_settings, :structure_type, :avatar

  def name
    consumer ? consumer.name : object.name
  end

  def email
    consumer ? consumer.email : object.email
  end

  def phone
    consumer ? consumer.phone : object.phone
  end

  def phone_normalized
    consumer ? consumer.phone_normalized : object.phone_normalized
  end

  def user
    UserSerializer.new(object.user, scope: scope, root: false) if object.user
  end

  def avatar
    AvatarSerializer.new(object.avatar, { :scope => scope, :root => false })
  end

  def invitation
    latest_invitation = object.invitations.pending.order(created_at: :asc).last
    InvitationSerializer.new(latest_invitation, scope: scope, root: false) if latest_invitation
  end

  def consumer
    @consumer ||= object.consumer
  end

  # Since: 1.1.9
  def folder_settings
    ActiveModel::ArraySerializer.new(object.user_folder_settings,
      root: false,
      each_serializer: ::Api::Mobile::V2::UserFolderSettingSerializer,
      scope: scope
    )
  end
end