FactoryGirl.define do
  factory :business do
    name  { Faker::Name.name }
    entity_type { Faker::Commerce.product_name }
    address_zip { Faker::Address.zip }
    address_city { Faker::Address.city }
    address_state { Faker::Address.state }
    address_street { Faker::Address.street_address }
    standard_category { StandardCategory.first ? StandardCategory.first : FactoryGirl.create(:standard_category) }
  end
end
