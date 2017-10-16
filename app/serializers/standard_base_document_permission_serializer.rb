class StandardBaseDocumentPermissionSerializer < ActiveModel::Serializer
  attributes :id, :owners, :permissions

  def permissions
    if Rails.mobile_app_version and Gem::Version.new(Rails.mobile_app_version) >= Gem::Version.new("1.2.1")
      permissions_list = object.permissions
    else
      permissions_list = object.permissions.where.not(value: Permission::WRITE)
    end
    ActiveModel::ArraySerializer.new(permissions_list,
      root: false, each_serializer: PermissionSerializer, scope: scope
    )
  end

  def owners
    ActiveModel::ArraySerializer.new(object.owners, :each_serializer => StandardBaseDocumentOwnerSerializer, :scope => scope)
  end
end