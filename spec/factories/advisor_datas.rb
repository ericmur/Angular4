require 'factory_girl'

FactoryGirl.define do
  factory :advisor_data do
    advisor_type { AdvisorData.advisor_types.keys.sample }
  end
end
