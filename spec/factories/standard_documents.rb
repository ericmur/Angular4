FactoryGirl.define do
  factory :standard_document do
    name { Faker::Name.title }

    transient do
      with_owner_list []
    end

    after :build do  |document, evaluator|
      evaluator.with_owner_list.each do |owner|
        document.owners.build(owner: owner)
      end
    end
  end

  trait :with_consumer_owner do
    after :build do |standard_document|
      consumer = FactoryGirl.create(:consumer)
      standard_document.consumer_id = consumer.id
      standard_document.owners << StandardBaseDocumentOwner.new(
        owner_id:   consumer.id,
        owner_type: 'User'
      )
    end
  end

  trait :with_standard_folder do
    after :create do |standard_document|
      standard_folder = FactoryGirl.create(:standard_folder)
      FactoryGirl.create(:standard_folder_standard_document, standard_base_document: standard_document, standard_folder: standard_folder)
    end
  end

  trait :with_client_owner do
    after :build do |standard_document|
      standard_document.owners << StandardBaseDocumentOwner.new(
        owner_id:   FactoryGirl.create(:client).id,
        owner_type: 'Client'
      )
    end
  end

  trait :with_standard_document_fields do
    after :create do |standard_document|
      standard_document.standard_document_fields << FactoryGirl.create_list(:standard_document_field, 2)
    end
  end
end
