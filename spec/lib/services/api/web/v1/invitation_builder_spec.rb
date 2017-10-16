require 'rails_helper'
require 'custom_spec_helper'

RSpec.describe Api::Web::V1::InvitationBuilder do
  before do
    load_standard_documents
    load_docyt_support
  end

  let!(:service) { Api::Web::V1::InvitationBuilder }

  let!(:group)      { create(:group, owner: advisor) }
  let!(:client)     { create(:client, advisor: advisor) }
  let!(:advisor)    { create(:advisor) }
  let!(:group_user) { create(:unconnected_group_user, group: group) }

  let!(:valid_client_invitation_params) {
    {
      client_id: client.id,
      client_type: Client.name.to_s,
      'invitation' => {
        email: Faker::Internet.email,
        phone: generate(:phone),
        email_invitation: true,
        text_invitation: true,
        text_content: Faker::Lorem.sentence
      }
    }
  }

  let!(:valid_group_user_invitation_params) {
    {
      client_id: group_user.id,
      client_type: GroupUser.name.to_s,
      'invitation' => {
        email: Faker::Internet.email,
        phone: generate(:phone),
        email_invitation: true,
        text_invitation: true,
        text_content: Faker::Lorem.sentence
      }
    }
  }

  let!(:invalid_invitation_params) {
    {
      client_id: Faker::Number.number(3),
      client_type: Client.name.to_s,
      'invitation' => {
        email: '',
        phone: '',
        email_invitation: '',
        text_invitation: '',
        text_content: ''
      }
    }
  }

  context '#create_invitation' do
    it 'should create invitation for client' do
      expect {
        service.new(advisor, valid_client_invitation_params).create_invitation
      }.to change{ Invitationable::Invitation.count }

      invitation = Invitationable::Invitation.last

      expect(invitation.created_by_user_id).to eq(advisor.id)
      expect(invitation.client_id).to eq(valid_client_invitation_params[:client_id])
      expect(invitation.phone).to eq(valid_client_invitation_params['invitation'][:phone])
      expect(invitation.email).to eq(valid_client_invitation_params['invitation'][:email])
      expect(invitation.text_content).to eq(valid_client_invitation_params['invitation'][:text_content])
      expect(invitation.text_invitation).to eq(valid_client_invitation_params['invitation'][:text_invitation])
      expect(invitation.email_invitation).to eq(valid_client_invitation_params['invitation'][:email_invitation])
    end

    it 'should create invitation for group_user' do
      expect {
        service.new(advisor, valid_group_user_invitation_params).create_invitation
      }.to change{ Invitationable::Invitation.count }

      invitation = Invitationable::Invitation.last

      expect(invitation.created_by_user_id).to eq(advisor.id)
      expect(invitation.group_user_id).to eq(valid_group_user_invitation_params[:client_id])
      expect(invitation.phone).to eq(valid_group_user_invitation_params['invitation'][:phone])
      expect(invitation.email).to eq(valid_group_user_invitation_params['invitation'][:email])
      expect(invitation.text_content).to eq(valid_group_user_invitation_params['invitation'][:text_content])
      expect(invitation.text_invitation).to eq(valid_group_user_invitation_params['invitation'][:text_invitation])
      expect(invitation.email_invitation).to eq(valid_group_user_invitation_params['invitation'][:email_invitation])
    end

    it 'should not create invitation' do
      expect {
        service.new(advisor, invalid_invitation_params).create_invitation
      }.not_to change{ Invitationable::Invitation.count }
    end
  end

end
