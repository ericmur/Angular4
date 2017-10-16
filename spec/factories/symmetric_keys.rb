FactoryGirl.define do
  factory :symmetric_key do
    created_for_user_id { Faker::Number.number(3) }
    created_by_user_id  { Faker::Number.number(3) }
    key_encrypted { Faker::Code.ean }
    iv_encrypted { Faker::Code.ean }
    document_id { Faker::Number.number(3) }
  end
end
