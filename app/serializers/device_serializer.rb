class DeviceSerializer < ActiveModel::Serializer
  attributes :id, :device_uuid, :confirmed_at, :name
end
