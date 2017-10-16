class Api::Web::V1::DocumentAssignmentService
  def initialize(current_advisor, client_id, document_assignment_params, params)
    @advisor     = current_advisor
    @client      = set_user(params)
    @documents   = set_documents(document_assignment_params[:ids])
    @client_type = get_client_type(@client, params) if @client

    @owner_client_id = client_id

    @errors_hash = {}
  end

  def assign_to_client
    ActiveRecord::Base.transaction do
      begin
        @documents.map { |document| set_document_owner(document) }
      rescue Exception => e
        @errors_hash['Error'] = e.message
        raise ActiveRecord::Rollback
      end
    end
    @documents
  end

  def errors
    @errors_hash
  end

  private

  def set_user(params)
    return set_group_user(params[:contact_id]) if group_user?(params)
    set_client(params[:client_id])
  end

  def set_document_owner(document)
    if @client_type == 'Consumer'
      document.share_with(by_user_id: @advisor.id, with_user_id: @client.consumer.id)
      document.document_owners.build(owner: User.find(@client.consumer.id)).save
    elsif @client_type == 'Client'
      document.document_owners.build(owner: Client.find(@client.id)).save
    elsif @client_type == 'GroupUser'
      owner_client = set_client(@owner_client_id)
      document.share_with(by_user_id: @advisor.id, with_user_id: owner_client.consumer.id)
      if @client.user_id
        document.share_with(by_user_id: @advisor.id, with_user_id: @client.user_id)
        document.document_owners.build(owner: User.find(@client.user_id)).save
      else
        document.document_owners.build(owner: GroupUser.find(@client.id)).save
      end
    else
      raise "Invalid client type #{@client_type}"
    end
  end

  def set_documents(ids)
    Document.owned_by(@advisor.id).where(id: ids)
  end

  def set_client(id)
    @advisor.clients_as_advisor.find_by(id: id)
  end

  def set_group_user(id)
    GroupUser.find_by(id: id)
  end

  def get_client_type(client, params)
    return params[:contact_type] if group_user?(params)
    client.consumer_id ? 'Consumer' : 'Client'
  end

  def group_user?(params)
    params[:contact_type] == "GroupUser"
  end
end
