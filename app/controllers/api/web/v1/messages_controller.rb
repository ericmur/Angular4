class Api::Web::V1::MessagesController < Api::Web::V1::ApiController
  before_action :set_message_query, only: [:index, :search]

  def index
    messages = @messages_query.get_messages

    @chat.set_messages_as_read(current_advisor)

    render status: 200, json: messages, each_serializer: ::Api::Web::V1::MessageSerializer,
      chat_info: {
        chat_docs_count: @chat.chat_documents.size,
        chat_users_count: @chat.chatable_users.size,
        chat_messages_count: @chat.messages.size
       },
      meta_key: :chat_info
  end

  def search
    messages = @messages_query.search_messages

    render status: 200, json: messages, each_serializer: ::Api::Web::V1::MessageSerializer,
      chat_info: {
        chat_docs_count: @chat.chat_documents.size,
        chat_users_count: @chat.chatable_users.size,
        chat_messages_count: messages.size
       },
      meta_key: :chat_info
  end

  private

  def set_message_query
    @messages_query = ::Api::Web::V1::MessagesQuery.new(current_advisor, params)
    @chat = @messages_query.get_chat
  end

end
