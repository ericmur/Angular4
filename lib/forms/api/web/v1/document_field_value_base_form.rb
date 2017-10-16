class Api::Web::V1::DocumentFieldValueBaseForm < Api::Web::V1::BaseForm
  include Mixins::DocumentFieldValueValidateHelper

  attribute :input_value, String
  attribute :local_standard_document_field_id, Integer
  attribute :document_id, Integer
  attribute :document_field_id, Integer
  attribute :user_id, Integer

  validate :is_correct_type
  validate :is_document_field_presence

  protected

  def set_user_id_for_encryption(attributes)
    params = attributes

    params.delete(:document_field_id) if params.has_key?(:document_field_id)

    params
  end

  def is_document_field_presence
    unless BaseDocumentField.find_by(id: document_field_id)
      errors.add(:document_field, "Document field don't found")
    end
  end

  def is_correct_type
    document_field = BaseDocumentField.find_by(id: document_field_id)

    unless check_value_data_type(input_value, document_field.data_type)
      errors.add(:data_type, "Unknown data_type")
    end
  end
end
