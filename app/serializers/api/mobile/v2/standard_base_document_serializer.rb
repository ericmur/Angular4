class Api::Mobile::V2::StandardBaseDocumentSerializer < ActiveModel::Serializer
  attributes :id, :name, :rank, :document_type, :size, :created_by_id, :show, :owners
  attributes :standard_folder_standard_documents, :with_pages, :icon_url, :width, :height
  attributes :field_descriptions, :standard_base_document_account_types, :permissions

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

  def show
    object.default
  end

  def rank
    if object.rank.present?
      object.rank
    else
      if sfsd = object.standard_folder_standard_documents.first
        sfsd.rank ? sfsd.rank : 0
      else
        0
      end
    end
  end

  def width
    object.dimension ? object.dimension.width : nil
  end

  def height
    object.dimension ? object.dimension.height : nil
  end

  def document_type
    object.type
  end

  def created_by_id
    object.consumer_id
  end

  def with_pages
    object.with_pages.nil? ? true : object.with_pages #For users prior to 1.1.5 with_pages used to be nil
  end

  def owners
    ActiveModel::ArraySerializer.new(object.owners,
      each_serializer: StandardBaseDocumentOwnerSerializer,
      scope: scope)
  end

  def standard_folder_standard_documents
    ActiveModel::ArraySerializer.new(object.standard_folder_standard_documents,
      each_serializer: Api::Mobile::V2::StandardFolderStandardDocumentSerializer,
      scope: scope)
  end

  def field_descriptions
    ActiveModel::ArraySerializer.new(object.standard_document_fields,
      each_serializer: Api::Mobile::V2::FieldDescriptionSerializer,
      scope: scope)
  end

  def screen_scale
    @screen_scale = params[:scale].present? ? params[:scale].to_i : 3

    if @screen_scale < 3
      @screen_scale = 2
    elsif @screen_scale > 3
      @screen_scale = 3
    end

    @screen_scale
  end

  def icon_url
    icon_name  = object.read_attribute("icon_name_#{screen_scale}x")

    return nil if icon_name.blank?
    asset_name = "documents/#{icon_name}"
    asset_host = Rails.application.config.action_controller.asset_host
    asset_prefix = Rails.application.config.assets.prefix
    asset_digest_path = Rails.application.assets[asset_name].digest_path
    [asset_host, asset_prefix, '/', asset_digest_path].join('')
  end
end
