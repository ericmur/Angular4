class Api::Web::V1::MessagesQuery
  def initialize(current_advisor, params)
    @per_page        = params[:per_page]
    @chat_id         = params[:chat_id]
    @search_phrase   = params[:search_phrase]
    @from_message_id = params[:from_message_id]
    @chat = get_chat
  end

  def search_messages
    @chat.messages
      .joins(
        'LEFT JOIN
          chat_documents
        ON
          chat_documents.message_id = messages.id'
      )
      .where(
        "chat_documents.message_id IS NULL
        AND
          messages.text ILIKE :search", search: "%#{@search_phrase}%"
      )
  end

  def get_messages
    if @from_message_id.presence
      @chat.messages.includes(sender: :avatar).where('id < ?', @from_message_id).order(:created_at).last(@per_page || 20).reverse
    else
      @chat.messages.includes(sender: :avatar).order(:created_at).last(@per_page || 20)
    end
  end

  def get_chat
    @chat ||= Chat.find(@chat_id)
  end

end
