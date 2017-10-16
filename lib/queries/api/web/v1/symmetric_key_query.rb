class Api::Web::V1::SymmetricKeyQuery

  def initialize(current_advisor, params = { })
    @current_advisor = current_advisor
  end

  def get_documents
    base_query = Document.joins(:symmetric_keys).where(symmetric_keys: {created_for_user_id: @current_advisor.id})
  end

  def get_documents_count
    documents = get_documents
    documents.count
  end
end
