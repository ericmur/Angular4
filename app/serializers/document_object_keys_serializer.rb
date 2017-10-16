class DocumentObjectKeysSerializer < ActiveModel::Serializer
  attributes :id, :state, :original_file_name, :original_file_key
end
