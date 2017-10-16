class Api::Mobile::V2::BusinessSerializer < ActiveModel::Serializer
  attributes :id, :name, :business_partners, :avatar, :folder_settings, :standard_category_id

  delegate :current_user, to: :scope

  def business_partners
    ActiveModel::ArraySerializer.new(object.business_partners,
      root: false,
      each_serializer: ::Api::Mobile::V2::BusinessPartnerSerializer,
      scope: scope
    )
  end

  def avatar
    AvatarSerializer.new(object.avatar, { root: false })
  end

  def folder_settings
    ActiveModel::ArraySerializer.new(object.user_folder_settings.where(user: current_user),
      root: false,
      each_serializer: ::Api::Mobile::V2::UserFolderSettingSerializer,
      scope: scope
    )
  end
end