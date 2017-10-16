FactoryGirl.define do
  factory :document_field_value do
    # Uncommenting bellow line caused 
    # ArgumentError: Trait not registered: input_value

    # input_value
  end

  trait :with_integer_value do 
    after :build do |document_field_value|
      document_field_value.input_value = Random.rand(0..1_000_000)
    end
  end

  trait :with_text_value do
    after :build do |document_field_value|
      document_field_value.input_value = Faker::Lorem::sentence
    end
  end
end
