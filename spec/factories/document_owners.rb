FactoryGirl.define do
  factory :document_owner do
    owner { FactoryGirl.create(:consumer) }
  end

end
