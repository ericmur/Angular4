FactoryGirl.define do
  factory :chat do

    trait :with_users do
      after(:create) do |chat|
        advisor = FactoryGirl.create(:advisor)
        chat.chatable_users << advisor
        consumer = FactoryGirl.create(:consumer)
        FactoryGirl.create(:client, :consumer => consumer, :advisor => advisor)
        chat.chatable_users << consumer
      end
    end
  end
end
