FactoryGirl.define do
  factory :cloud_service_authorization do
    user
    uid 'vlad@docyt.com'
    cloud_service
    token { Faker::Lorem.characters(64) }
  end
end
