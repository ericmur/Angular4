FactoryGirl.define do
  factory :consumer_to_consumer_invitation, class: 'Invitationable::ConsumerToConsumerInvitation' do
    email
    phone
    invitee_type { 'Consumer' }
  end
end
