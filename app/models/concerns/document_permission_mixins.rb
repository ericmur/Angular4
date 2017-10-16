require 'active_support/concern'

module DocumentPermissionMixins
  extend ActiveSupport::Concern

  def create_document_permissions_for(user, permission_type)
    DocumentPermission.create_permissions_if_needed(self, user, permission_type)
  end

  def destroy_document_permissions_for(user)
    document_permissions.where(user: user).destroy_all
  end

  def editable_by?(user)
    permitted_to?(DocumentPermission::EDIT, user)
  end

  def sharee_editable_by?(user)
    permitted_to?(DocumentPermission::EDIT_SHAREE, user)
  end

  def owner_editable_by?(user)
    permitted_to?(DocumentPermission::EDIT_OWNER, user)
  end

  def shareable_by?(user)
    permitted_to?(DocumentPermission::SHAREE, user)
  end

  def destroyable_by?(user)
    permitted_to?(DocumentPermission::DELETE, user)
  end

  def permitted_to?(permission_type, user)
    document_permissions.where(user: user, value: permission_type).exists?
  end

  # This method mostly used when deleting and transfering (upon invitation) document's owner.
  # When deleting owner, it's possible that owner might still have role for document.
  # For instance:
  # Document-1 has owner UserA, GroupUserB, GroupUserC (both GroupUsers is unconnected).
  # When UserA decide to remove GroupUserB, we will remove the permissions for GroupUserB owner.
  # However in this case GroupUserB owner, UserA, still remain the owner of Document-1.
  # Based on the case, we will remove permission for UserA and collect permission type candidates
  # to be re-assigned to UserA.
  def rebuild_document_permissions_for(user)
    destroy_document_permissions_for(user)
    document_permission_type = nil

    if uploader == user
      document_permission_type = DocumentPermission::UPLOADER
    end

    if document_permission_type.blank?
      if self.business_document? && self.document_business_partner?(user.id)
        document_permission_type = DocumentPermission::BUSINESS_PARTNER
      elsif !self.business_document?
        document_permission_type = document_permission_type_candidate_from_owners(user)
      end
    end

    if document_permission_type.blank?
      document_permission_type = document_permission_type_candidate_from_sharees(user)
    end

    unless document_permission_type.blank?
      create_document_permissions_for(user, document_permission_type)
    end
  end

  def document_permission_type_candidate_from_sharees(user)
    if sharees_for_documents.select{ |sharee| sharee == user }.first
      DocumentPermission::SHAREE
    else
      nil
    end
  end

  def document_permission_type_candidate_from_owners(user, options={})
    document_permission_type = nil
    document_owners.reload

    # Find candidates for permission type based on document_owners associated to user (if any)
    permission_type_candidates = document_owners.map do |document_owner|
      return nil unless document_owner.persisted?
      document_permission_type_aux = nil
      if document_owner.connected?
        if document_owner.owner == user
          document_permission_type_aux = DocumentPermission::OWNER
        end
      else
        permission_owner_class = document_owner.owner.class.name
        if permission_owner_class == 'GroupUser'
          if document_owner.owner.group.owner == user
            document_permission_type_aux = DocumentPermission::CUSTODIAN
          end
        elsif permission_owner_class == 'Client'
          if document_owner.owner.connected?
            if document_owner.owner.consumer == user
              document_permission_type_aux = DocumentPermission::OWNER
            elsif document_owner.owner.advisor == user
              document_permission_type_aux = DocumentPermission::CUSTODIAN
            end
          end
        end
      end
      document_permission_type_aux
    end.reject(&:nil?)

    document_permission_type = permission_type_candidates.select{ |t| t == DocumentPermission::OWNER }.first
    if document_permission_type.blank?
      document_permission_type = permission_type_candidates.select{ |t| t == DocumentPermission::CUSTODIAN }.first
    end

    document_permission_type
  end

end