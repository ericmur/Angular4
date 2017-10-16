class UserSerializer < ActiveModel::Serializer
  attributes :id, :email, :phone, :phone_normalized, :phone_confirmed_at
  attributes :first_name, :last_name, :middle_name, :avatar, :type, :has_pin, :device_confirmed

  def avatar
    AvatarSerializer.new(object.avatar, { :root => false })
  end

  def device_confirmed
    if serialization_options[:device_uuid].present?
      object.has_device_confirmed?(serialization_options[:device_uuid])
    end
  end

  def has_pin
    object.has_pin?
  end

  def type
    object.advisor? ? "Advisor" : "User"
  end
end
