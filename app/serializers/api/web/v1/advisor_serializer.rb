class Api::Web::V1::AdvisorSerializer < ActiveModel::Serializer
  attributes :id, :email, :unverified_phone, :unverified_email, :phone_normalized, :phone_confirmed_at,
             :authentication_token, :has_unread_notifications, :unread_notifications_count,
             :full_name, :password_updated_at, :category_name, :upload_email, :avatar, :email_confirmed_at, :is_support,
             :web_app_is_set_up, :web_phone_confirmed_at, :first_name, :clients_count, :employees_count, :contractors_count,
             :contacts_count, :consumer_account_type_id, :current_workspace_id, :current_workspace_name, :payment_history, :user_credits,
             :current_business_name, :business_names

  has_many :businesses

  def businesses
    if object.consumer_account_type and object.consumer_account_type.business?
      object.businesses
    else
      []
    end
  end
  
  def avatar
    object.avatar if object.avatar
  end

  def clients_count
    object.clients_as_advisor.count
  end

  def employees_count
    object.group_users.where(label: GroupUser::EMPLOYEE).count
  end

  def contractors_count
    object.group_users.where(label: GroupUser::CONTRACTOR).count
  end

  def contacts_count
    object.group_users.where.not(label: [GroupUser::EMPLOYEE, GroupUser::CONTRACTOR]).count
  end

  def has_unread_notifications
    Api::Web::V1::NotificationsQuery.new(object, {}).get_unread_notifications(false).count > 0 ? true : false
  end

  def unread_notifications_count
    Api::Web::V1::NotificationsQuery.new(object, {}).get_unread_notifications(false).count
  end

  def full_name
    object.name.strip
  end

  def category_name
    object.standard_category.name if object.standard_category
  end

  def is_support
    object.docyt_support?
  end

  def web_app_is_set_up
    object.web_app_is_set_up?
  end

  def payment_history
    object.payment_transactions.last
  end

  def user_credits
    object.user_credit
  end

end
