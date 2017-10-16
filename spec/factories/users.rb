require 'factory_girl'

FactoryGirl.define do

  sequence :phone do |n|
    '413-687-%04i' % n
  end

  factory :user do
    email { Faker::Internet.email }
    phone { FactoryGirl.generate(:phone) }
    phone_confirmed_at Time.now
    app_type { User::WEB_APP }
    password { 'test_password' }
    password_confirmation { 'test_password' }
  end

  factory :consumer, class: User do
    first_name { Faker::Name.first_name }
    last_name { Faker::Name.last_name }
    email { Faker::Internet.email }
    pin   "123456"
    pin_confirmation "123456"
    phone { FactoryGirl.generate(:phone) }
    phone_confirmed_at Time.now
    app_type { User::MOBILE_APP }
    password { 'test_password' }
    password_confirmation { 'test_password' }
    unverified_email { email }
    unverified_phone { phone }
  end

  factory :consumer_without_name, class: User do
    email { Faker::Internet.email }
    pin   "123456"
    pin_confirmation "123456"
    phone { FactoryGirl.generate(:phone) }
    phone_confirmed_at Time.now
    app_type { User::MOBILE_APP }
    password { 'test_password' }
    password_confirmation { 'test_password' }
  end
end
