class DocumentOwnerSerializer < ActiveModel::Serializer
  attributes :id, :owner_id, :owner_type, :user_id, :owner_or_uploader_id, :owner_name
end