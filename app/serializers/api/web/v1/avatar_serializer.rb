class Api::Web::V1::AvatarSerializer < ActiveModel::Serializer
  attributes :id, :s3_object_key
end
