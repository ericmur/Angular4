class QuickConsumerSerializer < ActiveModel::Serializer
  attributes :id, :email, :total_storage_size, :total_pages_count, :limit_storage_size, :limit_pages_count, :avatar, :email_confirmed, :upload_email, :user_credit

  delegate :params, to: :scope

  def email_confirmed
    object.email_confirmed?
  end

  def avatar
    AvatarSerializer.new(object.avatar, { :scope => scope, :root => false })
  end

  def user_credit
    ::Api::Mobile::V2::UserCreditSerializer.new(object.user_credit, { :scope => scope, :root => false })
  end

end
