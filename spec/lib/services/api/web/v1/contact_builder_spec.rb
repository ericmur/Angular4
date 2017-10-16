require 'rails_helper'
require 'custom_spec_helper'

RSpec.describe Api::Web::V1::ContactBuilder do
  before do
    load_standard_documents
    load_docyt_support
  end

  let!(:service) { Api::Web::V1::ContactBuilder }

  let!(:advisor) { create(:advisor) }

  let!(:standard_group) { create(:standard_group) }

  let!(:valid_contact_params) {
    {
      email: Faker::Internet.email,
      phone: FactoryGirl.generate(:phone),
      name: Faker::Name.name,
      standard_group_id: standard_group.id
    }
  }

  let!(:valid_invitation_params) {
    {
      email: Faker::Internet.email,
      phone: generate(:phone),
      email_invitation: true,
      text_invitation: true,
      text_content: Faker::Lorem.sentence
    }
  }

  let!(:invalid_contact_params) {
    {
      email: '',
      phone: FactoryGirl.generate(:phone)+'0000',
      name: ''
    }
  }

  let!(:invalid_invitation_params) {
    {
      email: '',
      phone: '',
    }
  }

  context "create_contact_and_invitation" do

    it 'should create contact' do
      service_instance = service.new(advisor, valid_contact_params)

      expect {
        service_instance.create_contact_and_invitation
      }.to change(GroupUser, :count).by(1)

      expect(service_instance.contact.name).to eq(valid_contact_params[:name])
      expect(service_instance.contact.email).to eq(valid_contact_params[:email])
      expect(service_instance.contact.phone).to eq(valid_contact_params[:phone])
      expect(service_instance.errors).to eq({})
    end

    it 'should create contact and invitation' do
      valid_contact_params['invitation'] = valid_invitation_params
      service_instance = service.new(advisor, valid_contact_params)

      expect {
        service_instance.create_contact_and_invitation
      }.to change(Invitationable::Invitation, :count).by(1)

      expect(service_instance.errors).to eq({})
    end

    it 'should not create a contact with invalid params' do
      service_instance = service.new(advisor, invalid_contact_params)

      expect {
        service_instance.create_contact_and_invitation
      }.not_to change(GroupUser, :count)

      expect(service_instance.errors['contact_errors']).to include("Name can't be blank")
      expect(service_instance.errors['contact_errors']).to include("Group can't be blank")
      expect(service_instance.errors['contact_errors']).to include("Phone is an invalid number")
    end

    it 'should not create an invitation with invalid invitation params' do
      valid_contact_params['invitation'] = invalid_invitation_params
      service_instance = service.new(advisor, valid_contact_params)

      expect {
        service_instance.create_contact_and_invitation
      }.not_to change(Invitationable::Invitation, :count)

      expect(service_instance.errors['invitation_errors']).to include("Phone can't be blank")
      expect(service_instance.errors['invitation_errors']).to include("Email can't be blank")
    end

    it 'should not create an invitation with valid params but unconfirmed advisor' do
      valid_contact_params['invitation'] = valid_invitation_params
      service_instance = service.new(advisor, valid_contact_params)
      advisor.update(first_name: nil, last_name: nil)

      expect {
        service_instance.create_contact_and_invitation
      }.not_to change(Invitationable::Invitation, :count)

      expect(service_instance.errors['invitation_errors']).to include(I18n.t('errors.invitation.require_fullname'))
    end

  end
end
