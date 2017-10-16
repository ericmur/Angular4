require 'rails_helper'
require 'spec_helper'
require 'custom_spec_helper'

describe Api::Web::V1::InvitationsController do
  before do
    stub_request(:post, /.twilio.com/).to_return(status: 200)
    allow(TwilioClient).to receive_message_chain("get_instance.account.messages.create") { true }
    load_standard_documents
    load_docyt_support
  end

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
      text_content: ''
    }
  }

  context '#create' do
    it 'should create and return a invitation when params valid' do
      request.headers['X-USER-TOKEN'] = advisor.authentication_token

      expect {
        post :create, client_id: client.id, invitation: valid_invitation_params
      }.to change(Invitationable::AdvisorToConsumerInvitation, :count).by(1)

      invitation = JSON.parse(response.body)['invitation']

      expect(invitation['email']).to eq(valid_invitation_params[:email])
      expect(invitation['phone']).to eq(valid_invitation_params[:phone])
      expect(invitation['text_content']).to eq(valid_invitation_params[:text_content])
      expect(response).to have_http_status(201)
    end

    it 'should return invitation errors when invitation params invalid' do
      request.headers['X-USER-TOKEN'] = advisor.authentication_token

      expect {
        post :create, client_id: client.id, invitation: invalid_invitation_params
      }.not_to change(Invitationable::AdvisorToConsumerInvitation, :count)

      errors = JSON.parse(response.body)

      expect(errors['invitation_errors']).to include("Phone can't be blank")
      expect(errors['invitation_errors']).to include("Email can't be blank")
      expect(response).to have_http_status(422)
    end
  end

  context "#destroy" do
    let!(:invitation) { create(:advisor_to_consumer_invitation, created_by_user: advisor, email: Faker::Internet.email) }

    it "should delete invitation if invitation exists" do
      request.headers['X-USER-TOKEN'] = advisor.authentication_token

      expect {
        delete :destroy, client_id: client.id, id: invitation.id
      }.to change(Invitationable::AdvisorToConsumerInvitation, :count).by(-1)

      invitation_response = JSON.parse(response.body)

      expect(invitation_response['id']).to eq(invitation.id)
      expect(response).to have_http_status(200)
    end

    it "should return 404 if invitation not exists" do
      request.headers['X-USER-TOKEN'] = advisor.authentication_token

      expect {
        delete :destroy, client_id: client.id, id: Faker::Number.number(3)
      }.not_to change(Invitationable::Invitation, :count)

      invitation_response = JSON.parse(response.body)

      expect(invitation_response).to be_empty
      expect(response).to have_http_status(404)
    end
  end
end
