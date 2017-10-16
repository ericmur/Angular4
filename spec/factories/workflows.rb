FactoryGirl.define do
  factory :workflow do
    name     { Faker::Commerce.product_name }
    admin_id { Faker::Number.number(3) }
    end_date { Faker::Date.forward(10) }
    purpose  { Faker::Commerce.product_name }
  end
end
