class Api::Mobile::V2::BusinessInformationSerializer < ActiveModel::Serializer
  attributes :id, :name, :phone, :email, :address_street, :address_city, :address_state, :address_zip, :standard_category_id
end