FactoryGirl.define do
  factory :standard_category do
    name { Faker::Name.title }
  end

  trait :with_consumer do
    after :create do |standard_category|
      standard_category.update(consumer_id: FactoryGirl.create(:consumer).id)
    end
  end

end
