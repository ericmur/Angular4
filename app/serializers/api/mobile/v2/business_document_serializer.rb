class Api::Mobile::V2::BusinessDocumentSerializer < ActiveModel::Serializer
  attributes :id, :business_id, :document_id
end