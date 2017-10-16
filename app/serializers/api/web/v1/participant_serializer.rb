class Api::Web::V1::ParticipantSerializer < ActiveModel::Serializer
  attributes :id, :full_name, :avatar

  has_one :avatar, serializer: Api::Web::V1::AvatarSerializer
end
