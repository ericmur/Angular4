FactoryGirl.define do
  factory :invitation, class: 'Invitationable::Invitation' do
    email { 'sugam@docyt.com' }
    phone { Faker::PhoneNumber.cell_phone }
  end

  trait :with_email_and_phone do
    after :build do |invitation|
      invitation.email = 'sugam@docyt.com'
      invitation.phone = Faker::PhoneNumber.cell_phone
    end
  end
end
