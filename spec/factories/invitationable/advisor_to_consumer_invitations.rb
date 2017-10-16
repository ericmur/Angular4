FactoryGirl.define do
  factory :advisor_to_consumer_invitation, class: 'Invitationable::AdvisorToConsumerInvitation' do
    email
    phone
    invitee_type { 'Consumer' }
  end
end
