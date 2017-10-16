require 'active_support/concern'

module StandardBaseDocumentPermissionMixins
  extend ActiveSupport::Concern

  def create_permissions_entries(standard_document, permissions_list, user)
    permissions_list.each do |value|
      standard_document.owners.each do |standard_base_document_owner|
        Rails.logger.info "standard_document -> #{user.id} #{standard_base_document_owner.owner_type} #{standard_base_document_owner.owner_id} #{value}"

        if standard_base_document_owner.owner_type == 'GroupUser'
          next unless user.group_users_as_group_owner.where(id: standard_base_document_owner.owner_id).exists?
        elsif standard_base_document_owner.owner_type == 'Client'
          next unless user.clients_as_advisor.where(id: standard_base_document_owner.owner_id).exists?
        end

        folder_structure_owner = standard_base_document_owner.owner
        next if standard_document.permissions.where(user: user, folder_structure_owner: folder_structure_owner, value: value).exists?
        standard_document.permissions.create!(user: user, folder_structure_owner: folder_structure_owner, value: value)
      end
    end

    standard_document.standard_folder_standard_documents.each do |sfsd|
      standard_folder = sfsd.standard_folder
      next unless standard_folder.consumer_id.present?
      standard_folder.owners.each do |standard_base_document_owner|
        permissions_list.each do |value|
          Rails.logger.info "standard_folder -> #{user.id} #{standard_base_document_owner.owner_type} #{standard_base_document_owner.owner_id} #{value}"

          if standard_base_document_owner.owner_type == 'GroupUser'
            next unless user.group_users_as_group_owner.where(id: standard_base_document_owner.owner_id).exists?
          elsif standard_base_document_owner.owner_type == 'Client'
            next unless user.clients_as_advisor.where(id: standard_base_document_owner.owner_id).exists?
          end

          folder_structure_owner = standard_base_document_owner.owner
          next if standard_folder.permissions.where(user: user, folder_structure_owner: folder_structure_owner, value: value).exists?
          standard_folder.permissions.create!(user: user, folder_structure_owner: folder_structure_owner, value: value)
        end
      end
    end
  end

  def generate_standard_base_document_permissions_for_owner(standard_document, user, is_business_document, is_document_business_partner)
    if is_business_document
      if is_document_business_partner
        create_permissions_entries(standard_document, Permission::VALUES, user)
      else
        create_permissions_entries(standard_document, [Permission::VIEW], user)
      end
    else
      create_permissions_entries(standard_document, Permission::VALUES, user)
    end
  end
end