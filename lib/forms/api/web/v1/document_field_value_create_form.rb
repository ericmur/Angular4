class Api::Web::V1::DocumentFieldValueCreateForm < Api::Web::V1::DocumentFieldValueBaseForm
  def get_document_field
    @document_field_value if @document_field_value.persisted?
  end

  private

  def persist!
    params = set_user_id_for_encryption(attributes)
    @document_field_value = DocumentFieldValue.new(params)

    @document_field_value.save
  end
end
