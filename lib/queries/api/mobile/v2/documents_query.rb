class Api::Mobile::V2::DocumentsQuery
  def initialize(current_user, params)
    @current_user    = current_user
    @params          = params
  end

  def get_documents
    user_id = @params[:user_id] ? @params[:user_id] : @current_user.id
    @documents = Document.joins(:symmetric_keys).where("symmetric_keys.created_for_user_id = ?", user_id)
    @documents = @documents.union(Document.owned_by(user_id))
    @documents = @documents.order(group_rank: :asc).order(created_at: :desc)
    @documents = @documents.where.not(standard_document_id: nil)

    @documents.distinct
  end
end