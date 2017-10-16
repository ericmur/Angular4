module Mixins::ClientOrGroupUserHelper
  def set_user_object(current_advisor, client_id, group_user_id = nil)
    return get_client(current_advisor, client_id) if client_id

    get_group_user(current_advisor, group_user_id) if group_user_id
  end

  def get_shared_ids_by_object(current_advisor, object)
    object_class = object.class.name.to_s

    case object_class
    when Client.name.to_s    then object.documents_ids_shared_with_advisor
    when Business.name.to_s  then object.business_documents.pluck(:document_id)
    when GroupUser.name.to_s then object.documents_ids_shared_with_user(current_advisor)
    when User.name.to_s
      invalid_type_exception(object_class) unless current_advisor.id == object.id
      current_advisor.document_ownerships.pluck(:document_id)
    else invalid_type_exception(object_class)
    end
  end

  # Set params
  def set_client_from_params(params)
    return params[:client_id] if params[:contact_id].blank?

    return params[:contact_id] if params[:contact_type] == Client.to_s

    check_contact_type(params)
  end

  def set_group_user_from_params(params)
    return if params[:contact_id].blank?

    return params[:contact_id] if params[:contact_type] == GroupUser.to_s

    check_contact_type(params)
  end

  def check_contact_type(params)
    unless params[:contact_type] == Client.to_s || params[:contact_type] == GroupUser.to_s
      invalid_type_exception(params[:contact_type])
    end
  end

  # Get user
  def get_client(current_advisor, client_id)
    current_advisor.clients_as_advisor.find_by(id: client_id)
  end

  def get_group_user(current_advisor, group_user_id)
    group_user = GroupUser.find_by_id(group_user_id)
    return unless group_user
    consumer = group_user.group.owner

    if current_advisor.current_workspace_id == ConsumerAccountType::BUSINESS
      return unless current_advisor.clients_as_advisor.find_by_consumer_id(consumer.id)
    end

    group_user
  end

  def get_object(params = {})
    if params[:business_id]
      @current_advisor.businesses.find_by(id: @business_id)
    else
      user(params[:own_documents])
    end
  end

  private

  def user(own_documents)
    own_documents ? @current_advisor : set_user_object(@current_advisor, @client_id, @group_user_id)
  end

  def invalid_type_exception(class_name)
    raise "Invalid type: #{class_name}"
  end
end
