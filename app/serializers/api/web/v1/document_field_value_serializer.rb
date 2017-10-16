class Api::Web::V1::DocumentFieldValueSerializer < ActiveModel::Serializer
  attributes :id, :value

  def value
    field_value = field_value_obj

    if field_value
      field_value.user_id = scope.id
    end

    field_value ? field_value.field_value : nil
  end

  private
  
  def field_value_obj
    return unless object.document_id

    DocumentFieldValue.find_with_user_access(object, scope)
  end
end
