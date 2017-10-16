class Api::Web::V1::DocumentFieldValueUpdateForm < Api::Web::V1::DocumentFieldValueBaseForm
  def to_model
    DocumentFieldValue.find_by(id: id)
  end

  private

  def persist!
    params = set_user_id_for_encryption(attributes)
    document_field_value = self.to_model
    document_field_value.user_id = params[:user_id]
    document_field_value.update({ input_value: self.attributes[:input_value] })
  end
end
