class Api::Web::V1::DocumentFieldsSerializer < ActiveModel::Serializer
  attributes :id, :name, :value, :data_type, :value_id, :field_id

  #Some fields are marked as secure and those will be encrypted just like documents. So they have to be decrypted before they can be shown.
  def value
    field_value = field_value_obj
    if field_value
      field_value.user_id = scope.id #Needed to call field_value.decrypt_value
    end
    field_value ? field_value.field_value : nil
  end

  private
  def field_value_obj
    if object.document_id
      doc_field_value = DocumentFieldValue.where(:document_id => object.document_id, :local_standard_document_field_id => object.field_id).first
      doc_field_value && doc_field_value.document.accessible_by_me?(scope) ? doc_field_value : nil
    else
      nil
    end
  end
end
