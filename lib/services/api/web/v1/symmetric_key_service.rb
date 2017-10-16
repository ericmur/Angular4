class Api::Web::V1::SymmetricKeyService

  def initialize(advisor, params = {})
    @params    = params
    @advisor   = advisor
    @document  = params[:document]
    @client_id = params[:client_id]
    @temporary = params[:temporary]

    @chat_members_params    = params[:chat_members]
    @document_owners_params = params[:document_owners_params]
  end

  def create_keys
    client       = get_client       if @client_id
    chat_members = get_chat_members if @chat_members_params

    #set_symmetric_key is needed here because we need to give access to the client as well in case this was connected group user. For un-connected group user, we are going to be fine
    #even without this line because document.rb#build_s3_key will take care of giving share access to the client as well.
    if @document_owners_params.present? and @document_owners_params.first["owner_type"] == "GroupUser"
      @document.share_with(by_user_id: @advisor.id, with_user_id: client.user_id)
    else
      #Documents sent in chat have no owners yet, but we need to share it with the client.
      set_symmetric_keys_for_chat_members(@document, chat_members) if @temporary && chat_members
    end
  end

  private

  def set_symmetric_keys_for_chat_members(document, chat_members)
    chat_members.each { |chat_member| document.share_with(by_user_id: @advisor.id, with_user_id: chat_member.id) }
  end

  def get_client
    Client.find(@client_id)
  end

  def get_chat_members
    @chat_members_params.map { |chat_member| chat_member['type'].constantize.find(chat_member['id']) }
  end

end
