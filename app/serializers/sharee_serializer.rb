class ShareeSerializer < ActiveModel::Serializer
  attributes :id, :first_name, :avatar, :created_by_user_id

  def avatar
    AvatarSerializer.new(object.avatar, { :scope => scope, :root => false })
  end

  def document
    serialization_options[:document]
  end

  def created_by_user_id
    symmetric_key = document.symmetric_keys.where.not(created_by_user_id: nil).where(created_for_user_id: object.id).first
    if symmetric_key
      symmetric_key.created_by_user_id
    end
  end
end
