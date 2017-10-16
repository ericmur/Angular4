FactoryGirl.define do
  factory :email do
    from_address { Faker::Internet.email }
    to_addresses { Faker::Internet.email }
    subject 'This is the subject'
    body_text 'This is the body'
  end

end
