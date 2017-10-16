class StandardBaseDocumentOwnerSerializer < ActiveModel::Serializer
  attributes :id, :owner_id, :owner_type
end