class Api::Mobile::V2::FieldValueSuggestionsController < Api::Mobile::V2::ApiController
  before_action :load_standard_document

  def index
    suggestions = FieldValueSuggestion.for_system_and_user(current_user.id).for_standard_document(@standard_document.id)
    matched_suggestion_data = suggestions.map { |s| s.suggestions_for_field(params[:field_name]) }.flatten
    render status: :ok, json: matched_suggestion_data
  end

  private

  def load_standard_document
    @standard_document = StandardDocument.find(params[:standard_document_id])
  end
end