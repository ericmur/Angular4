class Api::Web::V1::DocumentUploaderSerializer < ActiveModel::Serializer
  attributes :email, :phone_normalized
end
