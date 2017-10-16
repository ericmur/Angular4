class Api::Mobile::V2::DocumentPermissionSerializer < ActiveModel::Serializer
  attributes :id, :document_id, :user_id, :value
end