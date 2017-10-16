class Api::Mobile::V2::StandardCategorySerializer < ActiveModel::Serializer
  attributes :id, :name, :consumer_id
end