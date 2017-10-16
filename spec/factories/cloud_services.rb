FactoryGirl.define do
  sequence :name do |n|
    ['Dropbox', 'Drive'][n % 2]
  end

  factory :cloud_service do
    name { FactoryGirl.generate(:name) }
  end
end
