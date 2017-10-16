class Api::Web::V1::ChatMemberSerializer < ActiveModel::Serializer
  attributes :id, :parsed_fullname, :member_type

  has_one :avatar, serializer: Api::Web::V1::AvatarSerializer

  def member_type
    object.class.name.to_s
  end
end
