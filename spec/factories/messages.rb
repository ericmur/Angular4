FactoryGirl.define do
  factory :message, class: 'Messagable::Message' do
    chat    { create(:chat, :with_users ) }
    sender  { chat.chatable_users.sample }
    text    { Faker::Lorem.paragraph(2) }
  end

  trait :web do
    after :build do |message|
      message.type = "Messagable::WebMessage"
    end
  end

  trait :sms do
    after :build do |message|
      message.type = "Messagable::SmsMessage"
    end
  end

  trait :email do
    after :build do |message|
      message.type = "Messagable::EmailMessage"
    end
  end

  trait :with_message_users do
    after :create do |message|
      message.create_notifications_for_chat_users!
    end
  end

end
