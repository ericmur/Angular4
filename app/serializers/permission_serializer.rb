class PermissionSerializer < ActiveModel::Serializer
  attributes :id, :user_id, :standard_base_document_id, :folder_structure_owner_id, :folder_structure_owner_type, :value
end
