class Api::Web::V1::DocumentOwnerSerializer < ActiveModel::Serializer
  attributes :id, :owner_name, :owner_avatar, :owner_id , :owner_type

  def owner_name
    object.owner.owner_name || object.owner.owner_email
  end

  def owner_avatar
    object.owner.owner_avatar
  end

end
