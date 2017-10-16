FactoryGirl.define do
  factory :standard_document_field do
    name { Faker::Lorem.word }
    field_id { Faker::Number.number(3) }
    data_type { %w(int float date expiry_date due_date year string text zip state country boolean url currency phone).sample }
  end

end
