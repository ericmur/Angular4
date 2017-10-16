FactoryGirl.define do
  factory :standard_folder do
    name { Faker::Name.title }

    trait :with_consumer do
      after :build do |standard_folder|
        standard_folder.consumer_id = FactoryGirl.create(:consumer).id
        standard_folder.owners << FactoryGirl.create(:standard_base_document_owner)
      end
    end
  end

end