class Api::Mobile::V2::StandardFolderStandardDocumentSerializer < ActiveModel::Serializer
  attributes :id, :standard_folder_id, :standard_base_document_id
end
