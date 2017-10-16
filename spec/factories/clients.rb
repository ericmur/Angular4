require 'factory_girl'

FactoryGirl.define do
  factory :client do
    advisor
    name  { "#{Faker::Name.first_name} #{Faker::Name.last_name}" }
    email { Faker::Internet.email }
    phone { FactoryGirl.generate(:phone) }
    business
  end

  trait :connected do
    after :build do |client|
      client.consumer = FactoryGirl.create(:consumer)
    end
  end
end
