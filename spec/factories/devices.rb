require 'factory_girl'

FactoryGirl.define do
  sequence :device_uuid do |n|
    'a56as-123sas-479as-%04i' % n
  end
  
  factory :device do
    user
    device_uuid { FactoryGirl.generate(:device_uuid) }
    confirmation_sent_at 5.minutes.ago
    confirmed_at Time.now
  end
end
