class Api::Web::V1::DocumentBuilder

  def initialize(current_advisor, document_params, params)
    @params      = params
    @advisor     = current_advisor
    @temporary   = params['document']['temporary']
    @client_id   = params['document']['client_id']
    @document_id = params['document']['id']
    @business_id = params['document']['business_id']

    @chat_members    = params['document']['chat_members']
    @category_params = params['document']['standard_document']
    @document_params = document_params
    @document_owners_params = params['document']['document_owners']

    set_business
  end

  def create_document
    document = Document.new(@document_params)
    document.uploader = @advisor

    set_source(document)

    if @business
      document.business_documents.build(business: @business)
    else
      set_document_owners(document)
    end

    document.save
    document.start_upload

    hash_params = set_hash_params(document, @client_id, @chat_members, @document_owners_params, @temporary)

    Api::Web::V1::SymmetricKeyService.new(@advisor, hash_params).create_keys if document.errors.empty?

    generate_permissions_for_business_partners(document) if @business

    document
  end

  def complete_document_upload
    document = set_document
    return unless document

    if @document_params['final_file_key'].blank?
      document.errors.add(:original_file_key, 'S3 file path is not set')
    else
      symmetric_key = document.symmetric_keys.for_user_access(@advisor.id).first

      document.original_file_key = @document_params['s3_object_key']
      document.final_file_key    = @document_params['final_file_key']
    end

    document
  end

  def update_category
    document = set_document
    return unless document

    if @category_params.blank?
      document.errors.add(:standard_document_id, 'Category is not set')
    else
      document.standard_document = find_or_create_category
    end

    if @temporary
      set_document_owners(document)
      document.share_with_system_for_duration(by_user_id: @advisor.id)
      document.start_convertation
    end

    if @business
      generate_folder_settings_for_business(document)
      generate_base_document_owners_for_business(document)
    end

    document.save
    document
  end

  private

  def set_document_owners(document)
    if @document_owners_params.present?
      @document_owners_params.each do |owner_hash|
        if owner_hash["owner_type"] == "GroupUser"
          group_user = GroupUser.find(owner_hash["owner_id"])

          document.document_owners.build(owner: group_user.user_id ? group_user.user : group_user)
        elsif owner_hash["owner_type"] == "Consumer" or owner_hash["owner_type"] == "User"
          document.document_owners.build(owner: User.find(owner_hash["owner_id"]))
        elsif owner_hash["owner_type"] == "Client"
          client = Client.find(owner_hash["owner_id"])

          document.document_owners.build(owner: client.consumer_id ? client.consumer : client)
        else
          document.errors.add(:base, "Invalid type: #{owner_hash['owner_type']}")
        end
      end
    else
      document.document_owners.build(owner: @advisor) unless document.is_source_chat?
    end
  end

  def find_or_create_category
    if @category_params['is_user_created']
      client = Client.find_by(id: @client_id)
      standard_document = StandardDocument.new(name: @category_params['name'], :consumer_id => @advisor.id)
      standard_document.standard_folder_standard_documents.build(:standard_folder_id => StandardFolder::MISC_FOLDER_ID)

      standard_document.owners << StandardBaseDocumentOwner.new(
        owner_id:   client.consumer_id ? client.consumer.id : client.id,
        owner_type: client.consumer_id ? 'User' : 'Client'
      )
      standard_document.save!
      standard_document
    else
      StandardBaseDocument.find(@category_params['id'])
    end
  end

  def set_document
    @advisor.symmetric_keys_for_me.find_by(document_id: @document_id).document
  end

  def set_source(document)
    document.source =
      if @temporary
        Chat::SOURCE[:web_chat]
      else
        User::SERVICE_PROVIDER_SOURCE
      end
  end

  def set_hash_params(document, client_id, chat_members, document_owners, temporary)
    {
      document:  document,
      client_id: client_id,
      temporary: temporary,
      chat_members: chat_members,
      document_owners: document_owners
    }
  end

  def generate_permissions_for_business_partners(document)
    @business.business_partners.each do |business_partner|
      DocumentPermission.create_permissions_if_needed(document, business_partner.user, DocumentPermission::BUSINESS_PARTNER)
      document.share_with(by_user_id: @advisor.id, with_user_id: business_partner.user.id)
    end
  end

  def generate_folder_settings_for_business(document)
    standard_document = document.standard_document

    return unless standard_document && document.business_document?

    users = User.where(id: document.all_sharees_ids_except_system).select('id')
    displayed_folders_ids = standard_document.standard_folder_standard_documents.map(&:standard_folder_id)

    document.businesses.each do |business|
      users.each do |user|
        displayed_folders_ids.each do |folder_id|
          user_folder_setting = user.user_folder_settings.find_by(standard_base_document_id: folder_id, folder_owner: business)

          return user_folder_setting.update(displayed: true) if user_folder_setting

          user.user_folder_settings.create(standard_base_document_id: folder_id, folder_owner: business, displayed: true)
        end
      end
    end
  end

  def generate_base_document_owners_for_business(document)
    document.businesses.each do |business|
      standard_document = document.standard_document
      return unless standard_document && standard_document.consumer_id

      create_owner_for_object(standard_document, business)

      standard_document.standard_folder_standard_documents.each do |sfsd|
        standard_folder = sfsd.standard_folder
        next unless standard_folder.consumer_id

        create_owner_for_object(standard_folder, business)
      end
    end
  end

  def create_owner_for_object(object, business)
    object.owners.create(owner: business) unless object.owners.where(owner: business).exists?
  end

  def set_business
    @business ||= @advisor.businesses.find_by(id: @business_id)
  end

end
