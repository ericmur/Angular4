class Api::Web::V1::ChatsController < Api::Web::V1::ApiController
  before_action :get_chats, only: :index
  before_action :get_chat,  only: :show

  def index
    render status: 200, json: @chats, each_serializer: ::Api::Web::V1::ChatSerializer
  end

  def show
    if @chat
      render status: 200, json: @chat, serializer: ::Api::Web::V1::ChatSerializer
    else
      render status: 404, json: {}
    end
  end

  private

  def get_chats
    @chats = Api::Web::V1::ChatsQuery.new(current_advisor).get_all_chats
  end

  def get_chat
    @chat = Chat.find_by(id: params[:id])
  end
end
