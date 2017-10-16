class Api::Web::V1::BusinessSerializer < ActiveModel::Serializer
  attributes :id, :name, :standard_category_id, :clients_count, :employees_count,
             :contractors_count, :type

  delegate :current_user, to: :scope

  has_one  :avatar,            serializer:      ::Api::Web::V1::AvatarSerializer
  has_many :business_partners, each_serializer: ::Api::Web::V1::BusinessPartnerSerializer

  def clients_count
    object.clients.size
  end

  def type
    object.class.name.to_s
  end
end
