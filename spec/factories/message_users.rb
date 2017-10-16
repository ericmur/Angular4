FactoryGirl.define do
  factory :message_user, class: "Messagable::MessageUser" do
      read_at { Date.today }
      created_at { 15.minutes.ago }
  end

end
