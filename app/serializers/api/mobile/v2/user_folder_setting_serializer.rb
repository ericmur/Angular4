class Api::Mobile::V2::UserFolderSettingSerializer < ActiveModel::Serializer
  attributes :id, :user_id, :folder_owner_id, :folder_owner_type, :standard_base_document_id, :displayed
end