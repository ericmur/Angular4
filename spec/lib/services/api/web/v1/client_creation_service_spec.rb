require 'rails_helper'
require 'custom_spec_helper'

RSpec.describe Api::Web::V1::ClientCreationService do
  before do
    load_standard_documents
    load_docyt_support
  end

  let!(:business_partner)  { create(:business_partner, user: confirmed_advisor) }
  let!(:confirmed_advisor) { create(:advisor, :with_fullname, :confirmed_email) }

  let!(:valid_client_params) {
    {
      'email' => Faker::Internet.email,
      'name'  => Faker::Name.name,
      'phone' => FactoryGirl.generate(:phone)
    }
  }

  let!(:valid_invitation_params) {
    {
      'email' => valid_client_params['email'],
      'phone' => valid_client_params['phone'],
      'email_invitation' => true,
      'text_invitation' => true
    }
  }

  let!(:invalid_client_params) {
    {
      'email' => '',
      'name'  => '',
      'phone' => FactoryGirl.generate(:phone)+'0000'
    }
  }

  let!(:invalid_invitation_params) {
    {
      'email' => '',
      'phone' => '',
    }
  }

  let!(:service)  { Api::Web::V1::ClientCreationService }

  context "create_client_and_invitation" do

    it 'should create client' do
      service_instance = service.new(confirmed_advisor, valid_client_params)

      expect {
        service_instance.create_client_and_invitation
      }.to change(Client, :count).by(1)

      expect(service_instance.client.name).to eq(valid_client_params['name'])
      expect(service_instance.client.email).to eq(valid_client_params['email'])
      expect(service_instance.client.phone).to eq(valid_client_params['phone'])
      expect(service_instance.errors).to eq({})
    end

    it 'should create client and invitation' do
      valid_client_params['invitation'] = valid_invitation_params
      service_instance = service.new(confirmed_advisor, valid_client_params)

      expect {
        service_instance.create_client_and_invitation
      }.to change(Invitationable::Invitation, :count).by(1)

      expect(service_instance.errors).to eq({})
    end

    it 'should not create a client with invalid params' do
      service_instance = service.new(confirmed_advisor, invalid_client_params)

      expect {
        service_instance.create_client_and_invitation
      }.not_to change(Client, :count)

      expect(service_instance.errors['client_errors']).to include("Name can't be blank")
      expect(service_instance.errors['client_errors']).to include("Phone is an invalid number")
    end

    it 'should not create an invitation with invalid invitation params' do
      valid_client_params['invitation'] = invalid_invitation_params
      confirmed_advisor.update(first_name: nil, last_name: nil)
      service_instance = service.new(confirmed_advisor, valid_client_params)

      expect {
        service_instance.create_client_and_invitation
      }.not_to change(Invitationable::Invitation, :count)

      expect(service_instance.errors['invitation_errors']).to include("Phone can't be blank")
      expect(service_instance.errors['invitation_errors']).to include("Email can't be blank")
    end

    it 'should not create an invitation with valid params but unconfirmed advisor' do
      valid_client_params['invitation'] = valid_invitation_params
      confirmed_advisor.update(first_name: nil, last_name: nil)
      service_instance = service.new(confirmed_advisor, valid_client_params)

      expect {
        service_instance.create_client_and_invitation
      }.not_to change(Invitationable::Invitation, :count)

      expect(service_instance.errors['invitation_errors']).to include(I18n.t('errors.invitation.require_fullname'))
    end

  end
end
