require 'rails_helper'
require 'spec_helper'
require 'custom_spec_helper'
require 's3'

RSpec.describe Invitationable::AdvisorToConsumerInvitation, type: :model do

  before(:each) do
    Faker::Config.locale = 'en-US'
    stub_docyt_support_creation
    standard_category = create(:standard_category)
    @inviter_user = FactoryGirl.create(:advisor, standard_category: standard_category)
    @inviter_user = verify_user_email(@inviter_user)
    create(:business_partner, user: @inviter_user)
  end

  context "Associations" do
    it { is_expected.to belong_to(:client) }
  end

  describe "Invitation without group user" do
    it 'should successfully create without group user' do
      FactoryGirl.create(:advisor_to_consumer_invitation, :with_email_and_phone, created_by_user: @inviter_user)
    end

    it 'should successfully generate random token' do
      @invitation = FactoryGirl.create(:advisor_to_consumer_invitation, :with_email_and_phone, created_by_user: @inviter_user)
      @invitation2 = FactoryGirl.create(:advisor_to_consumer_invitation, email: 'sid@docyt.com', phone: '4134567891', created_by_user: @inviter_user)
      expect(@invitation.token).not_to eq(nil)
      expect(@invitation2.token).not_to eq(nil)
      expect(@invitation.token).not_to eq(@invitation2.token)
    end

    it 'should require full name of user' do
      @inviter_user2 = FactoryGirl.create(:consumer, first_name: nil, last_name: nil)
      @inviter_user2 = verify_user_email(@inviter_user2)
      expect {
        FactoryGirl.create(:advisor_to_consumer_invitation, :with_email_and_phone, created_by_user: @inviter_user2)
      }.to raise_error(ActiveRecord::RecordInvalid, /#{I18n.t('errors.invitation.require_fullname')}/)
    end

    it 'should require text or email selection' do
      expect {
        FactoryGirl.create(:advisor_to_consumer_invitation, :with_email_and_phone, created_by_user: @inviter_user, text_invitation: false, email_invitation: false)
      }.to raise_error(ActiveRecord::RecordInvalid, /#{I18n.t('errors.invitation.require_type_selection')}/)
    end

    it 'should successfully create for text invitation only' do
      FactoryGirl.create(:advisor_to_consumer_invitation, :with_email_and_phone, created_by_user: @inviter_user, email_invitation: false)
    end

    it 'should successfully create for email invitation only' do
      FactoryGirl.create(:advisor_to_consumer_invitation, :with_email_and_phone, created_by_user: @inviter_user, text_invitation: false)
    end

    it 'should only sent 1 invitation per email' do
      FactoryGirl.create(:advisor_to_consumer_invitation, email: 'sugam@docyt.com', phone: '4134567891', created_by_user: @inviter_user)
      expect {
        FactoryGirl.create(:advisor_to_consumer_invitation, email: 'sugam@docyt.com', phone: '4134567890', created_by_user: @inviter_user)
      }.to raise_error(ActiveRecord::RecordInvalid, /Invitation already sent to that email/)
    end

    it 'should only sent 1 invitation per phone' do
      FactoryGirl.create(:advisor_to_consumer_invitation, email: 'sugam@docyt.com', phone: '4134567891', created_by_user: @inviter_user)
      expect {
        FactoryGirl.create(:advisor_to_consumer_invitation, email: 'tedi@docyt.com', phone: '4134567891', created_by_user: @inviter_user)
      }.to raise_error(ActiveRecord::RecordInvalid, /Invitation already sent to that phone number/)
    end

    it 'should allow invite same person from different user' do
      @inviter_user2 = FactoryGirl.create(:consumer, first_name: "Shilpa", last_name: "Dhir")
      User.verify_email_token(@inviter_user2.email_confirmation_token)
      @inviter_user2.reload

      FactoryGirl.create(:advisor_to_consumer_invitation, email: 'sugam@docyt.com', phone: '4134567890', created_by_user: @inviter_user)
      FactoryGirl.create(:advisor_to_consumer_invitation, email: 'sugam@docyt.com', phone: '4134567890', created_by_user: @inviter_user2)
    end
  end

  describe "Accepting invitation" do
    before(:each) do
      standard_group = FactoryGirl.create(:standard_group)
      @invited_user = FactoryGirl.create(:consumer, first_name: Faker::Name.first_name, last_name: Faker::Name.last_name)
      @invited_user = verify_user_email(@invited_user)
      @invited_user_group = FactoryGirl.create(:group, owner_id: @invited_user.id, standard_group: standard_group)

      @inviter_group = FactoryGirl.create(:group, owner_id: @inviter_user.id, standard_group: standard_group)
      @inviter_group_user = FactoryGirl.create(:group_user, :email => @invited_user.email, :phone => @invited_user.phone, :user => nil, :group => @inviter_group)
      @inviter_user.reload
    end
    let!(:client_params) do
      ActionController::Parameters.new({
        "client" => {
          "name"  => Faker::Name.name,
          "email" => @invited_user.email,
          "phone" => @invited_user.phone,
          "invitation" => {
            "email"            => @invited_user.email,
            "phone"            => @invited_user.phone,
            "text_invitation"  => true,
            "email_invitation" => true
          }
        }
      }).require(:client).permit(
          :email,
          :phone,
          :name,
          invitation: [
                        :email,
                        :phone,
                        :email_invitation,
                        :text_invitation
                      ]
        )
    end

    it 'should generate notifications' do
      client_creation_service = Api::Web::V1::ClientCreationService.new(@inviter_user, client_params)
      client_creation_service.create_client_and_invitation

      expect(@inviter_user.notifications.count).to eq(0)
      expect(@invited_user.notifications.count).to eq(1)

      expect(client_creation_service.invitation.accept_invitation!(@invited_user)).to eq(true)

      @inviter_user.reload
      expect(@inviter_user.notifications.count).to eq(1)
    end

    it 'should update state attributes' do
      client_creation_service = Api::Web::V1::ClientCreationService.new(@inviter_user, client_params)
      client_creation_service.create_client_and_invitation
      invitation = client_creation_service.invitation

      expect(invitation.accept_invitation!(@invited_user)).to eq(true)

      expect(invitation.accepted_by_user.id).to eq(@invited_user.id)
      expect(invitation.accepted_at.present?).to eq(true)
      expect(invitation.accepted?).to eq(true)
    end

    it 'should failed when invitation email/phone is not the same with invitee' do
      client_creation_service = Api::Web::V1::ClientCreationService.new(@inviter_user, client_params)
      client_creation_service.create_client_and_invitation
      invitation = client_creation_service.invitation
      @invited_user2 = FactoryGirl.create(:consumer, first_name: Faker::Name.first_name, last_name: Faker::Name.last_name)
      User.verify_email_token(@invited_user2.email_confirmation_token)
      @invited_user2.reload

      expect(invitation.accept_invitation!(@invited_user2)).to eq(false)

      expect(invitation.state).to eq('pending')
      expect(invitation.errors.count).to eq(1)
    end
  end
end
