class CalculateFieldValueSuggestionsJob < ActiveJob::Base
  queue_as :default

  def perform(user_id, standard_document_id, field_name, field_value)
    FieldValueSuggestion.create_suggestion_for_field(user_id, standard_document_id, field_name, field_value)
  end
end
