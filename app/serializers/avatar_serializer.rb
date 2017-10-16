class AvatarSerializer < ActiveModel::Serializer
  attributes :id, :s3_object_key, :state
end
