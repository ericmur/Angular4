class Api::Mobile::V2::DocumentShareeSerializer < ActiveModel::Serializer
  attributes :id, :first_name, :avatar, :created_by_user_id, :created_for_user_id

  def id
    object.created_for_user_id
  end

  def first_name
    object.created_for_user.first_name
  end

  def avatar
    AvatarSerializer.new(object.created_for_user.avatar, scope: scope, root: false)
  end
end