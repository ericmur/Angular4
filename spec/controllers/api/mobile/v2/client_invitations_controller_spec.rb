require 'rails_helper'
require 'custom_spec_helper'

describe Api::Mobile::V2::ClientInvitationsController do
  before do
    Rails.set_app_type(User::MOBILE_APP)
    load_standard_documents
    load_docyt_support
    load_startup_keys
    setup_logged_in_consumer(advisor, pin)
  end

  let!(:pin)     { Faker::Number.number(6) }
  let!(:client)  { create(:client, advisor: advisor) }
  let!(:advisor) { create(:advisor, :with_fullname) }

  let(:valid_invitation_params) {
    {
      email: client.email,
      phone: client.phone,
      text_invitation: true,
      email_invitation: true,
      text_content: Faker::Lorem.sentence
    }
  }

  let(:invalid_invitation_params) {
    {
      email: '',
      phone: '',
    }
  }

  context "#create" do
    it 'should create invitation when params valid' do
      expect {
        post :create, format: :json, device_uuid: @device.device_uuid, password_hash: @hsh, client_id: client.id, invitation: valid_invitation_params
      }.to change(Invitationable::AdvisorToConsumerInvitation, :count).by(1)

      invitation = JSON.parse(response.body)['invitation']

      expect(invitation['email']).to eq(valid_invitation_params[:email])
      expect(invitation['phone']).to eq(valid_invitation_params[:phone])
      expect(response).to have_http_status(200)
    end

    it 'should return invitation errors when invitation params invalid' do
      expect {
        post :create, format: :json, device_uuid: @device.device_uuid, password_hash: @hsh, client_id: client.id, invitation: invalid_invitation_params
      }.not_to change(Invitationable::AdvisorToConsumerInvitation, :count)

      result = JSON.parse(response.body)

      expect(result['errors']).to include("Phone can't be blank")
      expect(result['errors']).to include("Email can't be blank")
      expect(response).to have_http_status(422)
    end
  end
end
