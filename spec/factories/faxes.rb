FactoryGirl.define do
  factory :fax do
    sender     { create(:consumer) }
    fax_number { Faker::PhoneNumber.cell_phone }
  end
end
