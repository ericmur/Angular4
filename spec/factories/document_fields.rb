require 'factory_girl'

def set_consumer
  return Consumer.first.id if Consumer.count > 0

  FactoryGirl.create(:consumer)
end

FactoryGirl.define do
  factory :document_fields, class: "DocumentField" do
    name { Faker::Lorem::sentence }
    created_by_user_id { set_consumer }
    data_type { %w(int float date expiry_date due_date year string text zip state country boolean url currency phone).sample }
  end
end
