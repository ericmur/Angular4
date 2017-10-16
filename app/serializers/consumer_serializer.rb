#This represents the serializer for the user model that is rendered for requests from iPhone app. 
class ConsumerSerializer < ActiveModel::Serializer
  attributes :id, :email, :phone, :phone_normalized, :phone_confirmed_at,  :number_of_documents, :password_hash, :private_key
  attributes :total_storage_size, :total_pages_count, :limit_storage_size, :limit_pages_count, :avatar, :email_confirmed, :cloud_services
  attributes :group_user_labels, :family_group_id, :default_group, :contact_list_state, :contact_list_uploaded_offset, :contact_list_chunk_size
  attributes :first_name, :middle_name, :last_name, :number_of_expiring_documents, :advisors, :user_folder_settings, :upload_email, :type
  attributes :consumer_account_type_id, :advisors, :chats, :standard_category_id, :last_time_notifications_read_at, :number_of_suggested_documents
  attributes :clients, :standard_categories, :purchase_items, :fax_credit, :reviewed_latest_app_version, :businesses, :business_entity_types
  attributes :referral_url

  delegate :params, to: :scope
  delegate :current_user, to: :scope

  def type
    'Consumer'
  end
  
  def chats
    ActiveModel::ArraySerializer.new(object.chats, :each_serializer => ChatSerializer, scope: { user: object })
  end

  # Since: 1.1.9
  def clients
    ActiveModel::ArraySerializer.new(object.clients_as_advisor, each_serializer: ::Api::Mobile::V2::ClientSerializer)
  end

  # Since: 1.1.9
  def standard_categories
    system_categories = StandardCategory.only_system.except_support
    custom_categories = StandardCategory.for_user(object)
    categories_list = system_categories.union(custom_categories).order(consumer_id: :desc)
    ActiveModel::ArraySerializer.new(categories_list, each_serializer: ::Api::Mobile::V2::StandardCategorySerializer)
  end

  # Since: 1.2.0
  def purchase_items
    ActiveModel::ArraySerializer.new(PurchaseItem.all, each_serializer: ::Api::Mobile::V2::PurchaseItemSerializer)
  end

  # Since: 1.2.1
  def business_entity_types
    Business::ENTITY_TYPES
  end

  # Since: 1.2.1
  def businesses
    busines_list = Business.joins(:business_partners).where(business_partners: { user: object })
    business_ids = Document.joins({:business_documents => :business}).accessible_by_me(object).pluck("DISTINCT business_id")
    busines_list = busines_list.union(Business.where(id: business_ids))
    ActiveModel::ArraySerializer.new(busines_list, each_serializer: ::Api::Mobile::V2::BusinessSerializer, root: false, scope: scope)
  end

  # Since: 1.2.1
  def reviewed_latest_app_version
    review = object.review
    return false if review.blank?
    review.should_ask_review?(Rails.mobile_app_version) == false
  end

  # Since: 1.2.2
  def referral_url
    Rails.application.routes.url_helpers.referral_invite_url(referral_code: object.referral_code.code, host: ENV['SMTP_DOMAIN'], protocol: 'https')
  end

  def last_time_notifications_read_at
    if object.last_time_notifications_read_at
      object.last_time_notifications_read_at
    else
      Time.zone.now
    end
  end

  # check UserFolderSetting#folder_owner_identifier
  def user_folder_settings
    if Rails.mobile_app_version and Gem::Version.new(Rails.mobile_app_version) >= Gem::Version.new("1.1.1")
      folder_settings = object.user_folder_settings.displayed
    else
      folder_settings = object.user_folder_settings.hidden
    end
    folder_settings.order(folder_owner_id: :asc).group_by{ |d| d.folder_owner_identifier }.map{ |k,v| [k, v.map(&:standard_base_document_id)] }.to_h
  end

  def advisors
    if Rails.mobile_app_version and Gem::Version.new(Rails.mobile_app_version) >= Gem::Version.new("1.1.7")
      ActiveModel::ArraySerializer.new(object.advisors, :each_serializer => AdvisorSerializer, scope: { user: object })
    else
      #1.1.7 is when we introduced Service Providers in production. So don't return any for prior to 1.1.7
      []
    end
  end

  def cloud_services
    CloudService.all
  end

  def contact_list_state
    if object.iphone_contact_list
      object.iphone_contact_list.state
    else
      'pending'
    end
  end

  def contact_list_uploaded_offset
    if object.iphone_contact_list
      object.iphone_contact_list.uploaded_offset
    else
      0
    end
  end

  def contact_list_chunk_size
    UserContactList::CHUNK_SIZE
  end

  def group_user_labels
    account_type_key = nil
    account_types = JSON.parse(ERB.new(File.read("#{Rails.root}/config/consumer_account_types.json.erb")).result)
    account_types.each do |key, val|
      next if object.consumer_account_type.nil?
      if val["id"] == object.consumer_account_type.id
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

  def family_group_id
    std_group = StandardGroup.find_by_name(StandardGroup::FAMILY)
    std_group.id
  end

  def default_group
    group = object.groups_as_owner.first
    if group
      GroupSerializer.new(group, { :scope => scope, :root => false })
    end
  end

  def email_confirmed
    object.email_confirmed?
  end

  def avatar
    AvatarSerializer.new(object.avatar, { :scope => scope, :root => false })
  end

  def number_of_suggested_documents
    object.suggested_documents_count
  end

  def number_of_documents
    object.document_ownerships.count
  end

  def number_of_expiring_documents
    object.document_ownerships.joins(:document => :document_field_values).where("document_field_values.notification_level > 0").count
  end

  def password_hash
    object.password_hash(params[:pin]) unless params[:pin].blank?
  end

  def fax_credit
    object.user_credit.fax_credit
  end

  def dollar_credit
    object.user_credit.dollar_credit
  end

  def private_key
    if params[:pin]
      pgp = Encryption::Pgp.new({ :password => password_hash, :private_key => object.private_key })
      pgp.unencrypted_private_key
    else
      ""
    end
  end

end
