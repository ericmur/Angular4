class ChatMessagesController < ApplicationController
  def show
    @chat = Chat.find(params[:id])
    @chat.set_messages_as_read(current_user)

    @messages = Messagable::Message.where(chat_id: params[:id]).order(created_at: :desc)

    if params[:oldest_message_id].present? # last id in client's cache array
      oldest_message_id = params[:oldest_message_id].to_i - 1
      @messages = @messages.where("id <= ?", oldest_message_id).limit(20)
    elsif params[:oldest_refresh_id].present? # last id of max cache limit to be refreshed
      oldest_refresh_id = params[:oldest_refresh_id].to_i
      @messages = @messages.where(["id >= ?", oldest_refresh_id])
    else # initial data load
      @messages = @messages.limit(20)
    end

    respond_to do |format|
      format.json { render :json => @messages, each_serializer: MessageSerializer, root: 'chat_messages' }
    end
  end
end