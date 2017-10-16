require 'factory_girl'

FactoryGirl.define do
  factory :advisor, class: User do
    email { Faker::Internet.email }
    password { 'test_password' }
    password_confirmation { 'test_password' }
    phone { FactoryGirl.generate(:phone) }
    phone_confirmed_at Time.now
    authentication_token { Devise.friendly_token }
    standard_category { StandardCategory.first }
    consumer_account_type { ConsumerAccountType.first }
    app_type { User::WEB_APP }
    consumer_account_type_id { ConsumerAccountType::BUSINESS }
    first_name { Faker::Name.first_name }
    last_name { Faker::Name.last_name }
    after(:create) do |user|
      user.update_auth_encrypted_private_key('test_password')
    end
  end

  factory :docyt_support_advisor, class: User do
    email { "support@docyt.com" }
    password { 'test_password' }
    password_confirmation { 'test_password' }
    phone { FactoryGirl.generate(:phone) }
    phone_confirmed_at Time.now
    authentication_token { Devise.friendly_token }
    standard_category_id { StandardCategory::DOCYT_SUPPORT_ID }
    app_type { User::WEB_APP }
    after(:create) do |user|
      business = Business.new
      business.name                 = Faker::Company.name
      business.entity_type          = 'Support'
      business.address_street       = Faker::Address.street_name
      business.address_city         = Faker::Address.city
      business.address_state        = Faker::Address.state_abbr
      business.address_zip          = Faker::Address.zip
      business.standard_category_id = StandardCategory::DOCYT_SUPPORT_ID
      business.business_partners.build(user: user)
      business.save!
    end
  end

  factory :advisor_iphone, class: User do
    email { Faker::Internet.email }
    phone { FactoryGirl.generate(:phone) }
    phone_confirmed_at Time.now
    pin { '123456' }
    pin_confirmation { '123456' }
    authentication_token { Devise.friendly_token }
    consumer_account_type { ConsumerAccountType.first }
    app_type { User::MOBILE_APP }
    consumer_account_type_id { ConsumerAccountType::BUSINESS }
  end

  trait :with_auth_token do
    after :build do |advisor|
      advisor.authentication_token = Faker::Lorem.characters(10)
    end
  end

  trait :with_fullname do
    after :build do |advisor|
      advisor.first_name  = Faker::Name.name
      advisor.middle_name = Faker::Name.name
      advisor.last_name   = Faker::Name.name
    end
  end

  trait :confirmed_email do
    after :create do |advisor|
      advisor.update(email_confirmed_at: DateTime.now)
    end
  end

end
