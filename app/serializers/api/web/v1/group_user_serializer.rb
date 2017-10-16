class Api::Web::V1::GroupUserSerializer < ActiveModel::Serializer
  attributes :id, :avatar, :user

  def avatar
    if object.user_id
      ::AvatarSerializer.new(object.user.avatar, { :scope => scope, :root => false })
    else
      ::AvatarSerializer.new(object.avatar, { :scope => scope, :root => false })
    end
  end

end
