class Api::Web::V1::EmailSerializer < ActiveModel::Serializer
  attributes :id, :from_address, :to_addresses, :subject, :body_text, :body_html, :created_at
end
