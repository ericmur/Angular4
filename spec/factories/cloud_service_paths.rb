FactoryGirl.define do
  factory :cloud_service_path do
    consumer
    cloud_service_authorization
    path { '/' + Faker::Lorem.word + '/' + Faker::Lorem.word }
    path_display_name { '/' + Faker::Lorem.word + '/' + Faker::Lorem.word }
  end
end
