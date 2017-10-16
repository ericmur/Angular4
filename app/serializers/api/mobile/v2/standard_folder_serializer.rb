class Api::Mobile::V2::StandardFolderSerializer < ActiveModel::Serializer
  include Iconable

  attributes :id, :name, :rank, :document_type, :icon_name, :icon_url, :description, :category
  attributes :created_by_id, :owners, :standard_folder_standard_documents
  attributes :with_pages, :withPages #There was a bug in 1.1.5 where we introduced withPages for standardFolder on client side instead of with_pages, hence we have withPages here too
  attributes :standard_base_document_account_types, :permissions

  delegate :current_user, to: :scope
  delegate :params, to: :scope

  def permissions
    if object.consumer_id.present?
      if Rails.mobile_app_version and Gem::Version.new(Rails.mobile_app_version) >= Gem::Version.new("1.2.1")
        permissions_list = object.permissions
      else
        permissions_list = object.permissions.where.not(value: Permission::WRITE)
      end
      ActiveModel::ArraySerializer.new(permissions_list,
        root: false, each_serializer: PermissionSerializer, scope: scope
      )
    end
  end

  def standard_base_document_account_types
    ActiveModel::ArraySerializer.new(object.standard_base_document_account_types,
      root: false,
      each_serializer: Api::Mobile::V2::StandardBaseDocumentAccountTypeSerializer,
      scope: scope)
  end

  def iconable_object
    object
  end

  def name
    object.name
  end

  def document_type
    object.type
  end

  def owners
    ActiveModel::ArraySerializer.new(object.owners,
      each_serializer: StandardBaseDocumentOwnerSerializer,
      scope: scope)
  end

  def with_pages
    object.with_pages.nil? ? true : object.with_pages #For users prior to 1.1.5 with_pages used to be nil
  end

  #There was a bug in 1.1.5 where we introduced withPages for standardFolder on client side instead of with_pages, hence we have withPages here too
  def withPages
    object.with_pages.nil? ? true : object.with_pages #For users prior to 1.1.5 with_pages used to be nil
  end

end