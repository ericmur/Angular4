class ChatsUsersRelationSerializer < ActiveModel::Serializer
  attributes :chatable_id, :chatable_type
  def chatable_type
    if Rails.mobile_app_version and Gem::Version.new(Rails.mobile_app_version) >= Gem::Version.new("1.1.7")
      object.read_attribute(:chatable_type)
    else
      #Prior to 1.1.7 we had separate Service Provider and Consumer models. There were barely any users connected to service providers though.
      'Advisor'
    end
  end
end
