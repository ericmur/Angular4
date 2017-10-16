class Api::Web::V1::SearchDocumentSerializer < ActiveModel::Serializer
  attributes :id, :original_file_name, :created_at, :get_standard_folder_name,
    :get_standard_document_name, :first_standard_field, :second_standard_field

  def get_standard_folder_name
    object.attributes["standard_folder_name"]
  end

  def get_standard_document_name
    object.attributes["standard_document_name"]
  end

  def first_standard_field
    return unless object.respond_to?(:standard_field_id_1)

    field_value = DocumentFieldValue.where(:document_id => object.id, :local_standard_document_field_id => object.standard_field_id_1).first
    get_value(field_value)
  end

  def second_standard_field
    return unless object.respond_to?(:standard_field_id_2)

    field_value = DocumentFieldValue.where(:document_id => object.id, :local_standard_document_field_id => object.standard_field_id_2).first
    get_value(field_value)
  end

  private
  
  def get_value(field_value)
    field_value_obj = (field_value && field_value.document.accessible_by_me?(scope)) ? field_value : nil
    if field_value_obj
      field_value_obj.user_id = scope.id #Needed to call field_value_obj.decrypt_value
    end
    field_value_obj ? field_value_obj.field_value : nil
  end
end
