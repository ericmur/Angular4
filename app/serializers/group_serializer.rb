class GroupSerializer < ActiveModel::Serializer
  has_many :group_users

  attributes :id, :group_users
end
