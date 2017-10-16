class Api::Mobile::V2::DocumentBuilder
  def initialize(current_user, document_params, params)
    @current_user = current_user

    @document_id = params['id']
    @standard_document_id = document_params['standard_document_id']
    @temporary = params['temporary']
    @document_source = document_params['source']

    @document_params = document_params
    @owners_params = params['document_owners']
    @sharees_params = params['document_sharees']
    @businesses_params = params['businesses']
  end

  def create_document
    document = @current_user.uploaded_documents.build(@document_params)
    document.state = 'uploaded' if document.original_file_name.blank?
    if @temporary
      document.source = Fax::SOURCE
    end

    ActiveRecord::Base.transaction(requires_new: true) do
      begin
        set_document_owners(document)
        set_document_businesses(document)
        document.save!

        business_partners_users = get_business_partners_users(document)
        if document.business_document? && !business_partners_users.include?(@current_user.id)
          raise 'Not allowed to create Business Document'
        end

        generate_permissions_for_business_partners(document)
        document.generate_standard_base_document_permissions
        document.generate_folder_settings

        generate_folder_settings_for_business(document)
        generate_base_document_owners_for_business(document)
      rescue => e
        document.errors.add(:base, e.message) if document.errors.empty?
        raise ActiveRecord::Rollback
      end
    end

    document
  end

  def update_sharees!(document)
    document.transaction do
      begin
        new_sharee_ids = []
        revoked_sharee_ids = []

        @sharees_params.each do |sharees_hash|
          if sharees_hash['user_type'] == 'GroupUser'
            group_user = GroupUser.find_by(sharees_hash['user_id'])
            sharee_id = group_user.user_id
          elsif sharees_hash['user_type'] == 'Client'
            client = Client.find(sharees_hash['user_id'])
            sharee_id = client.consumer_id
          else
            sharee_id = sharees_hash['user_id'].to_i
          end

          if sharees_hash['delete'].present?
            revoked_sharee_ids << sharee_id
          else
            new_sharee_ids << sharee_id
          end
        end if @sharees_params.present?

        new_sharee_ids.each do |new_sharee_id|
          if document.symmetric_keys.for_user_access(new_sharee_id).select(:id).first.nil?
            if document.share_with(:by_user_id => @current_user.id, :with_user_id => new_sharee_id)
              document.notify_new_document_sharing(@current_user, new_sharee_id)
              if @current_user.has_advisor?(new_sharee_id)
                advisor = User.find_by_id(new_sharee_id)
                document.create_advisor_group_user!(@current_user, advisor) if advisor
              end
            else
              sharee_name = User.find(new_sharee_id)
              raise "Failed to share with #{sharee_name.first_name}"
            end
          end
        end

        revoked_sharee_ids.each do |revoked_sharee_id|
          sk = document.symmetric_keys.for_user_access(revoked_sharee_id).first
          next if sk.nil?
          if sk.created_by_user_id == @current_user.id || document.is_owned_by?(@current_user) || sk.created_for_user_id == revoked_sharee_id
            document.revoke_sharing(:with_user_id => revoked_sharee_id)
            document.notify_revoked_document_sharing(@current_user, revoked_sharee_id)
          else
            raise I18n.t('errors.document.cannot_delete_sharee')
          end
        end

        document.generate_standard_base_document_permissions
        document.generate_folder_settings

        generate_folder_settings_for_business(document)
        generate_base_document_owners_for_business(document)

      rescue => e
        ap e.backtrace if Rails.env.development?
        document.errors.add(:base, e.message)
        raise ActiveRecord::Rollback
      end
    end

    return document.errors.empty?
  end

  def update_owners!(document)
    document.transaction do
      begin
        owner_list_before_updating = get_users_ids_from_document_owners(document)

        deleted_owners_user_ids = remove_business_from_document!(document)
        new_document_owners = add_business_to_document!(document)

        deleted_owners_user_ids += remove_owners_from_document!(document)
        new_document_owners += add_owners_to_document!(document)

        users_ids_with_access = get_users_ids_from_document_owners(document)
        users_ids_deleted = deleted_owners_user_ids.select { |d| !users_ids_with_access.include?(d) }
        new_owner_user_ids = users_ids_with_access - owner_list_before_updating
        old_owner_user_ids = users_ids_with_access - new_owner_user_ids

        document.remove_symmetric_key_for_users(users_ids_deleted)
        document.remove_favorites_for_users(users_ids_deleted)
        document.update_owners_symmetric_key(@current_user)

        generate_permissions_for_business_partners(document)

        document.generate_standard_base_document_permissions
        document.generate_folder_settings

        generate_folder_settings_for_business(document)
        generate_base_document_owners_for_business(document)

        document.notify_old_owners_for_new_owners(@current_user, old_owner_user_ids) if new_owner_user_ids.present?
        document.notify_new_users(@current_user, new_owner_user_ids) if new_owner_user_ids.present?
        document.notify_deleted_owners(@current_user, deleted_owners_user_ids)

        document.recalculate_storage_size_for_owners(deleted_owners_user_ids) # Calculate storage size for deleted owners
        document.recalculate_storage_counter_later # Calculate storage size for current document owners

      rescue => e
        ap e.backtrace if Rails.env.development?
        document.errors.add(:base, e.message)
        raise ActiveRecord::Rollback
      end
    end

    document.errors.empty?
  end

  def update_category
    document = set_document
    return unless document

    if @standard_document_id.blank?
      document.errors.add(:standard_document_id, 'Category is not set')
    else
      document.standard_document = get_category
    end

    document.source = @document_source if @document_source

    # We have to change the uploader to current_user so that if current_user assigns another contact as the chat document owner,
    # they will not be able to add pages to that document after that.
    # Pages have to be added because document is being converted from pdf to images.
    if document.is_source_chat? && document.document_owners.empty? && document.standard_document_id_was.blank?
      document.uploader = @current_user
    end

    if @temporary
      document.share_with_system_for_duration(:by_user_id => @current_user.id)
      document.start_convertation
    end

    set_document_owners(document)
    set_document_businesses(document)

    if document.save
      set_symmetric_keys_for_owners(document)
      generate_permissions_for_business_partners(document)
      generate_folder_settings_and_permissions(document)
      generate_folder_settings_for_business(document)
      generate_base_document_owners_for_business(document)
    end

    document
  end

  def set_document_businesses(document)
    @businesses_params.each do |business_hash|
      business = Business.find(business_hash['business_id'])
      document.business_documents.build(business: business)
    end unless @businesses_params.blank?
  end

  def set_document_owners(document)
    return if document.is_source_fax?

    if @owners_params.present?
      @owners_params.each do |owner_hash|
        owner_id = owner_hash['owner_id']
        owner_type = owner_hash['owner_type']

        case owner_type
        when 'GroupUser'
          group_user = GroupUser.find(owner_id)
          if group_user.user.present?
            build_owner_if_needed(document, group_user.user)
          else
            build_owner_if_needed(document, group_user)
          end
        when 'User'
          user = User.find(owner_id)
          build_owner_if_needed(document, user)
        when 'Client'
          client = Client.find(owner_id)
          if client.user.present?
            build_owner_if_needed(document, client.user)
          else
            build_owner_if_needed(document, client)
          end
        else
          raise "Invalid type: #{owner_hash['owner_type']}"
        end
      end
    else
      unless document.standard_document.present? && document.standard_document.business_document?
        document.document_owners.build(owner: @current_user)
      end
    end
  end

  private

  def generate_permissions_for_business_partners(document)
    document.business_documents.each do |business_document|
      business_document.business.business_partners.each do |business_partner|
        DocumentPermission.create_permissions_if_needed(document, business_partner.user, DocumentPermission::BUSINESS_PARTNER)
        document.share_with(by_user_id: @current_user.id, with_user_id: business_partner.user.id)
      end
    end
  end

  def generate_folder_settings_for_business(document)
    standard_document = document.standard_document
    return if standard_document.blank?
    return unless document.standard_document.business_document?
    displayed_folders_ids = standard_document.standard_folder_standard_documents.map(&:standard_folder_id)
    users = User.where(id: document.all_sharees_ids_except_system).select('id')

    document.businesses.each do |business|
      users.each do |user|
        displayed_folders_ids.each do |folder_id|
          user_folder_setting = user.user_folder_settings.where(standard_base_document_id: folder_id, folder_owner: business).first
          if user_folder_setting
            user_folder_setting.displayed = true
          else
            user_folder_setting = user.user_folder_settings.build(standard_base_document_id: folder_id, folder_owner: business, displayed: true)
          end
          user_folder_setting.save
        end
      end
    end
  end

  def generate_base_document_owners_for_business(document)
    document.businesses.each do |business|
      standard_document = document.standard_document
      return unless (standard_document && standard_document.consumer_id.present?)

      unless standard_document.owners.where(owner: business).exists?
        standard_document.owners.create(owner: business)
      end

      standard_document.standard_folder_standard_documents.each do |sfsd|
        standard_folder = sfsd.standard_folder
        next unless standard_folder.consumer_id.present?
        unless standard_folder.owners.where(owner: business).exists?
          standard_folder.owners.create(owner: business)
        end
      end
    end
  end

  def get_users_ids_from_document_owners(document)
    users_ids = document.document_owners.map do |document_owner|
      owner = document_owner.owner
      case document_owner.owner_type
      when 'User'
        document_owner.owner_id
      when 'GroupUser'
        owner.group.owner_id
      when 'Client'
        if owner.connected?
          [owner.consumer_id, owner.advisor_id]
        else
          owner.advisor_id
        end
      else
        nil
      end
    end
    users_ids.flatten.uniq.reject(&:nil?)
  end

  def add_business_to_document!(document)
    return [] if @businesses_params.blank?

    new_document_owners = []
    @businesses_params.each do |business_hash|
      mark_for_deletion = business_hash['delete'].present?
      next if mark_for_deletion
      business_id = business_hash['business_id'].to_i

      business = get_business(@current_user, business_id)
      if business
        create_business_for_document!(business, document)
        business.business_partners.each do |business_partner|
          new_document_owners << create_owner_if_needed(document, business_partner.user)
        end
      end
    end

    new_document_owners
  end

  def remove_business_from_document!(document)
    return [] if @businesses_params.blank?

    deleted_owners = []
    @businesses_params.each do |business_hash|
      mark_for_deletion = business_hash['delete'].present?
      next unless mark_for_deletion
      business_id = business_hash['business_id'].to_i

      business = get_business(@current_user, business_id)
      if business
        users_ids = document.business_documents.where.not(business: business).map { |bd| bd.business.business_partners.pluck(:user_id) }.flatten
        business.business_partners.each do |business_partner|
          unless users_ids.include?(business_partner.user_id)
            deleted_owners << business_partner.user_id
            document.document_owners.where(owner: business_partner.user).destroy_all
          end
        end
        document.business_documents.where(business: business).destroy_all
      end
    end

    deleted_owners
  end

  def get_group_user(user, group_user_id)
    user.groups_as_owner.first.group_users.where(id: group_user_id).first
  end

  def get_client(user, client_id)
    user.clients_as_advisor.where(id: client_id).first
  end

  def get_group_user_by_user_id(user, user_id)
    user.groups_as_owner.first.group_users.where(user_id: user_id).first
  end

  def get_client_by_user_id(user, user_id)
    user.clients_as_advisor.where(consumer_id: user_id).first
  end

  def get_client_seat(user, advisor_id)
    user.client_seats.where(advisor_id: advisor_id).first
  end

  def get_business(user, business_id)
    business_partnership = user.business_partnerships.where(business_id: business_id).first
    business_partnership.business if business_partnership
  end

  def get_business_partners_users(document)
    document.business_documents.map do |business_document|
      business_document.business.business_partners.map do |business_partner|
        business_partner.user_id
      end
    end.flatten.uniq
  end

  def add_owners_to_document!(document)
    return [] if @owners_params.blank?

    new_document_owners = []
    @owners_params.each do |owner_hash|
      mark_for_deletion = owner_hash['delete'].present?
      next if mark_for_deletion

      owner_id = owner_hash['owner_id'].to_i
      owner_type = owner_hash['owner_type']

      case owner_type
      when 'GroupUser'
        group_user = get_group_user(@current_user, owner_id)
        if group_user
          new_document_owners << create_owner_if_needed(document, group_user.user_id ? group_user.user : group_user)
        end
      when 'Client'
        client = get_client(@current_user, owner_id)
        if client
          new_document_owners << create_owner_if_needed(document, client.consumer_id ? client.user : client)
        end
      when 'User'
        group_user = get_group_user_by_user_id(@current_user, owner_id)
        if group_user.present?
          new_document_owners << create_owner_if_needed(document, group_user.user_id ? group_user.user : group_user)
        else
          client = get_client_by_user_id(@current_user, owner_id)
          if client.present?
            new_document_owners << create_owner_if_needed(document, client.consumer_id ? client.user : client)
          elsif @current_user.id == owner_id
            new_document_owners << create_owner_if_needed(document, @current_user)
          end
        end
      else
        raise 'invalid owner type'
      end

    end

    new_document_owners
  end

  def remove_owners_from_document!(document)
    return [] if @owners_params.blank?

    deleted_owners = []
    @owners_params.each do |owner_hash|
      mark_for_deletion = owner_hash['delete'].present?
      next unless mark_for_deletion

      owner_id = owner_hash['owner_id'].to_i
      owner_type = owner_hash['owner_type']

      case owner_type
      when 'GroupUser'
        group_user = get_group_user(@current_user, owner_id)
        deleted_owners << group_user.user_id if group_user.user_id.present?
        owner_to_delete = group_user.user ? group_user.user : group_user
        document.document_owners.where(owner: owner_to_delete).destroy_all
      when 'Client'
        client = get_client(@current_user, owner_id)
        deleted_owners << client.consumer_id if client.consumer_id.present?
        owner_to_delete = client.consumer ? client.consumer : client
        document.document_owners.where(owner: owner_to_delete).destroy_all
      when 'User'
        # Check for GroupUser list
        group_user = get_group_user_by_user_id(@current_user, owner_id)
        if group_user.present?
          deleted_owners << owner_id
          owner_to_delete = group_user.user ? group_user.user : group_user
          document.document_owners.where(owner: owner_to_delete).destroy_all
        else
          # Check for Client list
          client = get_client_by_user_id(@current_user, owner_id)
          if client.present?
            deleted_owners << owner_id
            owner_to_delete = client.consumer ? client.consumer : client
            document.document_owners.where(owner: owner_to_delete).destroy_all
          else
            # Check for Advisor list
            client_seat = get_client_seat(@current_user, owner_id)
            if client_seat
              deleted_owners << owner_id
              document.document_owners.where(owner: client_seat.advisor).destroy_all
            elsif @current_user.id == owner_id
              document.document_owners.where(owner: @current_user).destroy_all
            end
          end
        end
      else
        raise 'invalid owner type'
      end
    end
    deleted_owners
  end

  def create_owner_if_needed(document, owner)
    document.document_owners.find_or_create_by!(owner: owner)
  end

  def build_owner_if_needed(document, owner)
    unless document.document_owners.where(owner: owner).exists?
      document.document_owners.build(owner: owner)
    end
  end

  def create_business_for_document!(business, document)
    unless document.business_documents.where(business: business).exists?
      document.business_documents.create!(business: business)
    end
  end

  def generate_folder_settings_and_permissions(document)
    document.generate_standard_base_document_permissions
    document.generate_folder_settings
  end

  def get_only_connected_owners_ids(document)
    document.document_owners.only_connected_owners.map(&:owner_id)
  end

  def set_symmetric_keys_for_owners(document)
    document.document_owners.each do |document_owner|
      if document_owner.connected?
        document.share_with(by_user_id: @current_user.id, with_user_id: document_owner.owner_id)
      else
        case document_owner.owner_type
        when 'GroupUser' # share with group owner
          document.share_with(by_user_id: @current_user.id, with_user_id: document_owner.owner.group.owner_id)
        when 'Client' # share with advisor since client is not connected
          document.share_with(by_user_id: @current_user.id, with_user_id: document_owner.owner.advisor_id)
        end
      end
    end
  end

  def get_category
    StandardBaseDocument.find(@standard_document_id)
  end

  def set_document
    @current_user.symmetric_keys_for_me.where(:document_id => @document_id).first.document
  end

end
