class StandardFolderStandardDocumentSerializer < ActiveModel::Serializer
  attributes :id, :name, :standard_folder_id, :standard_base_document_id, :with_pages
  attributes :rank, :document_type, :documents, :size, :created_by_id, :show
  attributes :owners, :permissions, :icon_url

  delegate :current_user, to: :scope
  delegate :params, to: :scope

  def size
    object.standard_base_document.size
  end

  def documents #User can have multiple documents in a standardDocument. For eg. a user has multiple passports
    if object.standard_base_document.type == 'StandardDocument'
      user_id = params[:user_id] ? params[:user_id] : current_user.id
      documents = Document.joins(:symmetric_keys).where(:standard_document_id => object.standard_base_document_id)
      documents = documents.where("symmetric_keys.created_for_user_id = #{user_id}")
      documents = documents.union(Document.owned_by(user_id).where(:standard_document_id => object.standard_base_document_id))
      documents = documents.order(group_rank: :asc).order(created_at: :desc) #Documents that user has access to
      if documents.first
        #DocumentSerializer.new(document, { :scope => scope, :root => false })
        ActiveModel::ArraySerializer.new(documents, :each_serializer => DocumentSerializer, :scope => scope)
      else
        []
      end
    else
      nil #StandardFolder
    end
  end

  def permissions
    if Rails.mobile_app_version and Gem::Version.new(Rails.mobile_app_version) >= Gem::Version.new("1.2.1")
      permissions_list = object.standard_base_document.permissions
    else
      permissions_list = object.standard_base_document.permissions.where.not(value: Permission::WRITE)
    end
    ActiveModel::ArraySerializer.new(permissions_list,
      root: false, each_serializer: PermissionSerializer, scope: scope
    )
  end

  def show
    object.standard_base_document.default
  end

  def name
    object.standard_base_document.name
  end

  def with_pages
    object.standard_base_document.with_pages.nil? ? true : object.standard_base_document.with_pages #For users prior to 1.1.5 with_pages used to be nil
  end

  def document_type
    object.standard_base_document.type
  end

  def created_by_id
    object.standard_base_document.consumer_id
  end

  def owners
    ActiveModel::ArraySerializer.new(object.standard_base_document.owners, :each_serializer => StandardBaseDocumentOwnerSerializer, :scope => scope)
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
    return nil if object.standard_base_document.blank?
    icon_name  = object.standard_base_document.read_attribute("icon_name_#{screen_scale}x")

    return nil if icon_name.blank?
    asset_name = "documents/#{icon_name}"
    asset_host = Rails.application.config.action_controller.asset_host
    asset_prefix = Rails.application.config.assets.prefix
    asset_digest_path = Rails.application.assets[asset_name].digest_path
    [asset_host, asset_prefix, '/', asset_digest_path].join('')
  end
end
