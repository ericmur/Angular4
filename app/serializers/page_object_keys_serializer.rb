class PageObjectKeysSerializer < ActiveModel::Serializer
  attributes :id, :page_num, :document_id, :state, 
    :s3_object_key, :original_s3_object_key, :version, 
    :final_file_md5, :original_file_md5
end
