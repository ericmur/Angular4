class Api::Mobile::V2::PurchaseItemSerializer < ActiveModel::Serializer
  attributes :id, :name, :product_identifier, :price, :fax_credit_value, :discount
end