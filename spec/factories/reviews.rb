FactoryGirl.define do
  factory :review do
    user
    refused false
    last_version '1.2.0'
  end

end
