class Api::Web::V1::ContactsQuery
  CONTACTS_PER_PAGE = 20

  def initialize(current_advisor, params)
    @page     = params[:page] || 1
    @params   = params
    @advisor  = current_advisor
    @per_page = params[:per_page] || CONTACTS_PER_PAGE

    @group_label = @params[:group_label]
    @group_users_table = GroupUser.arel_table
  end

  def get_contacts
    contacts.page(@page).per(@per_page)
  end

  def get_label_contacts
    client = Client.find_by(id: @params[:client_id])

    return GroupUser.none unless client && client.user

    default_query(client.user).where(label_subcondition)
  end

  def get_contacts_for_user
    user = get_user

    return GroupUser.none unless user

    base_query = default_query(user)

    consumer_acc_type_id = user.consumer_account_type_id

    if consumer_acc_type_id && consumer_acc_type_id != ConsumerAccountType::BUSINESS
      base_query = base_query.where(contacts_condition)
    end

    base_query
  end

  def get_contacts_for_group_owner
    user = User.find_by(id: @params[:user_id])

    return GroupUser.none unless user

    user.group_users_as_group_owner
  end

  def get_contact
    if @params[:contact_type] == Client.to_s
      Client.find(@params[:id])
    else
      GroupUser.find(@params[:id])
    end
  end

  private

  def label_subcondition
    if @group_label == GroupUser::EMPLOYEE || @group_label == GroupUser::CONTRACTOR
      @group_users_table[:label].eq(@group_label)
    else
      contacts_condition
    end
  end

  def contacts_condition
    @group_users_table[:label].not_eq(GroupUser::EMPLOYEE).and(@group_users_table[:label].not_eq(GroupUser::CONTRACTOR))
  end

  def default_query(user)
    user.group_users_as_group_owner.joins(group_user_advisors: :advisor).where("users.id = ?", @advisor.id)
  end

  def contacts
    if @params[:user_id]
      get_contacts_for_group_owner
    elsif @params[:group_label]
      get_label_contacts
    else
      get_contacts_for_user
    end
  end

  def get_user
    if @params[:client_id]
      entity = Client.find_by(id: @params[:client_id])
    else
      entity = GroupUser.find_by(id: @params[:group_user_id])
    end

    entity.user if entity
  end

end
