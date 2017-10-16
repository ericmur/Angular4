class Api::Mobile::V2::BusinessPartnerSerializer < ActiveModel::Serializer
  attributes :id, :user_id, :user

  def user
    UserSerializer.new(object.user, root: false)
  end
end