require 'rails_helper'
require 'spec_helper'
require 'custom_spec_helper'

RSpec.describe InvitationsController, :type => :controller do
  before(:each) do
    @standard_group = FactoryGirl.create(:standard_group)

    load_standard_documents
    load_docyt_support
    setup_logged_in_consumer
    load_startup_keys

    @group = FactoryGirl.create(:group, { :standard_group_id => @standard_group.id, :owner_id => @user.id })
    @group_user = FactoryGirl.create(:group_user, :email => 'tedi@docyt.com', :phone => '4134567890', :user => nil, :group => @group)
  end

  context "#create" do
    it 'should save invitation with group user' do
      post :create, :format => :json, :invitation => { :phone => '4100010001', :email => 'sugam@docyt.com', :email_invitation => 1, :text_invitation => 1, :group_user_id => @group_user.id, :invitee_type => "Consumer" }, :device_uuid => @device.device_uuid
      expect(response.status).to eq(200)
      expect(Invitationable::ConsumerToConsumerInvitation.count).to eq(1)
      invitation = Invitationable::ConsumerToConsumerInvitation.first
      expect(invitation.email).to eq('sugam@docyt.com')
      expect(invitation.phone).to eq('4100010001')
      expect(invitation.email_invitation).to eq(true)
      expect(invitation.text_invitation).to eq(true)
      @group_user.reload
      expect(invitation.group_user.id).to eq(@group_user.id)
    end

    it 'should only able to invite same group user once' do
      post :create, :format => :json, :invitation => { :phone => '4100010001', :email => 'sugam@docyt.com', :email_invitation => 1, :text_invitation => 1, :group_user_id => @group_user.id, :invitee_type => "Consumer" }, :device_uuid => @device.device_uuid
      expect(response.status).to eq(200)
      expect(Invitationable::ConsumerToConsumerInvitation.count).to eq(1)
      post :create, :format => :json, :invitation => { :phone => '4100010001', :email => 'sugam@docyt.com', :email_invitation => 1, :text_invitation => 1, :group_user_id => @group_user.id, :invitee_type => "Consumer" }, :device_uuid => @device.device_uuid
      expect(response.status).to eq(406)
      expect(Invitationable::ConsumerToConsumerInvitation.count).to eq(1)
    end

    it 'should save invitation only for text invitation' do
      post :create, :format => :json, :invitation => { :phone => '4100010001', :email => 'sugam@docyt.com', :email_invitation => 0, :text_invitation => 1, :group_user_id => @group_user.id, :invitee_type => "Consumer" }, :device_uuid => @device.device_uuid
      expect(response.status).to eq(200)
      expect(Invitationable::ConsumerToConsumerInvitation.count).to eq(1)
      invitation = Invitationable::ConsumerToConsumerInvitation.first
      expect(invitation.email).to eq('sugam@docyt.com')
      expect(invitation.phone).to eq('4100010001')
      expect(invitation.email_invitation).to eq(false)
      expect(invitation.text_invitation).to eq(true)
    end

    it 'should save invitation only for email invitation' do
      post :create, :format => :json, :invitation => { :phone => '4100010001', :email => 'sugam@docyt.com', :email_invitation => 1, :text_invitation => 0, :group_user_id => @group_user.id, :invitee_type => "Consumer" }, :device_uuid => @device.device_uuid
      expect(response.status).to eq(200)
      expect(Invitationable::ConsumerToConsumerInvitation.count).to eq(1)
      invitation = Invitationable::ConsumerToConsumerInvitation.first
      expect(invitation.email).to eq('sugam@docyt.com')
      expect(invitation.phone).to eq('4100010001')
      expect(invitation.email_invitation).to eq(true)
      expect(invitation.text_invitation).to eq(false)
    end

    it 'should require invitation type selection' do
      post :create, :format => :json, :invitation => { :phone => '4100010001', :email => 'sugam@docyt.com', :email_invitation => 0, :text_invitation => 0, :group_user_id => @group_user.id, :invitee_type => "Consumer" }, :device_uuid => @device.device_uuid
      expect(response.status).to eq(406)
      expect(Invitationable::ConsumerToConsumerInvitation.count).to eq(0)
    end

    it 'should update group user email and phone' do
      post :create, :format => :json, :invitation => { :phone => '4100010111', :email => 'sugam+1@docyt.com', :email_invitation => 1, :text_invitation => 1, :group_user_id => @group_user.id, :invitee_type => "Consumer" }, :device_uuid => @device.device_uuid
      expect(response.status).to eq(200)
      expect(Invitationable::ConsumerToConsumerInvitation.count).to eq(1)
      invitation = Invitationable::ConsumerToConsumerInvitation.first
      expect(invitation.group_user.email).not_to eq(@group_user.email)
      expect(invitation.group_user.phone).not_to eq(@group_user.phone)
      @group_user.reload
      expect(invitation.group_user.email).to eq(@group_user.email)
      expect(invitation.group_user.phone).to eq(@group_user.phone)
    end
  end

  context "#accept, #reject, #cancel, #reinvite" do
    before(:each) do
      @advisor             = FactoryGirl.create(:advisor, :with_fullname)
      @consumer            = FactoryGirl.create(:consumer)
      @consumer_group      = FactoryGirl.create(:group, { :standard_group_id => @standard_group.id, :owner_id => @consumer.id })
      @consumer_group_user = FactoryGirl.create(:group_user, :email => @user.email, :phone => @user.phone, :user => nil, :group => @consumer_group)
    end

    let!(:business_partner)  { create(:business_partner, user: @advisor) }

    let!(:consumer_invitation_params) do
      {
        :phone => @user.phone,
        :email => @user.email,
        :email_invitation => 1,
        :text_invitation => 1,
        :group_user_id => @consumer_group_user.id,
        :invitee_type => "Consumer"
      }
    end
    let!(:client_params) do
      ActionController::Parameters.new({
        "client" => {
          "name"  => Faker::Name.name,
          "email" => @user.email,
          "phone" => @user.phone,
          "invitation" => {
            "email"            => @user.email,
            "phone"            => @user.phone,
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
    let!(:advisor_to_consumer_invitation) do
      client_creation_service = Api::Web::V1::ClientCreationService.new(@advisor, client_params)
      client_creation_service.create_client_and_invitation
      client_creation_service.invitation
    end
    let!(:consumer_to_consumer_invitation) do
      invite                 = Invitationable::ConsumerToConsumerInvitation.new(consumer_invitation_params)
      invite.created_by_user = @consumer
      invite.save
      invite
    end

    before(:each) do
      @advisor_invitation  = advisor_to_consumer_invitation
      @consumer_invitation = consumer_to_consumer_invitation
    end

    context "#show" do
      it "should return invitation, AdvisorToConsumerInvitation" do
        get :show, :format => :json, id: @advisor_invitation.id, :device_uuid => @device.device_uuid

        expect(response.status).to eq(200)
        invitation = JSON.parse(response.body)
        expect(invitation['invitation']['id']).to eq(@advisor_invitation.id)
      end

      it "should return invitation, ConsumerToConsumerInvitation" do
        get :show, :format => :json, id: @consumer_invitation.id, :device_uuid => @device.device_uuid

        expect(response.status).to eq(200)
        invitation = JSON.parse(response.body)
        expect(invitation['invitation']['id']).to eq(@consumer_invitation.id)
      end
    end

    context "#accept" do
      let(:consumer_to_consumer_invitation_prepare) do
        @inviter_user = FactoryGirl.create(:consumer, first_name: Faker::Name.first_name, last_name: Faker::Name.last_name)
        @inviter_user = verify_user_email(@inviter_user)

        standard_group = create(:standard_group, name: Faker::Name.name)
        @inviter_user_group = FactoryGirl.create(:group, owner_id: @inviter_user.id, standard_group_id: standard_group.id)

        @user = verify_user_email(@user)
        @user_group = FactoryGirl.create(:group, owner_id: @user.id, standard_group_id: standard_group.id)

        @inviter_group_user = FactoryGirl.create(:group_user, :email => @inviter_user.email, :phone => @inviter_user.phone, :user => @user, :group => @inviter_user_group)
        @invited_group_user = FactoryGirl.create(:group_user, :email => @user.email, :phone => @user.phone, :user => nil, :group => @user_group)
      end

      context "source: email" do
        it "should accept invitation, AdvisorToConsumerInvitation" do
          expect(@advisor_invitation.pending?).to eq(true)
          put :accept, :format => :json, id: @advisor_invitation.id, :device_uuid => @device.device_uuid, source: Invitationable::Invitation::SOURCE[:email]

          @advisor_invitation.reload
          expect(response.status).to eq(200)
          expect(@advisor_invitation.accepted?).to eq(true)
        end

        it "should accept invitation with user_group_id, ConsumerToConsumerInvitation" do
          consumer_to_consumer_invitation_prepare

          @invitation = FactoryGirl.create(:consumer_to_consumer_invitation, :email => @user.email, :phone => @user.phone, created_by_user: @inviter_user, group_user: @inviter_group_user)

          expect(@invitation.pending?).to eq(true)
          post :accept, :format => :json, id: @invitation.id, group_user_id: @invited_group_user.id, source: Invitationable::Invitation::SOURCE[:email], :device_uuid => @device.device_uuid

          @invitation.reload
          expect(response.status).to eq(200)
          expect(@invitation.accepted?).to eq(true)
        end

        it "should accept invitation with group_user_label, ConsumerToConsumerInvitation" do
          consumer_to_consumer_invitation_prepare

          @invitation = FactoryGirl.create(:consumer_to_consumer_invitation, :email => @user.email, :phone => @user.phone, created_by_user: @inviter_user, group_user: @inviter_group_user)

          expect(@invitation.pending?).to eq(true)
          post :accept, :format => :json, id: @invitation.id, group_user_label: @inviter_group_user.label, source: Invitationable::Invitation::SOURCE[:email], :device_uuid => @device.device_uuid

          @invitation.reload
          expect(response.status).to eq(200)
          expect(@invitation.accepted?).to eq(true)
        end
      end

      context "source: phone" do
        it "should accept invitation, AdvisorToConsumerInvitation" do
          expect(@advisor_invitation.pending?).to eq(true)
          put :accept, :format => :json, id: @advisor_invitation.id, :device_uuid => @device.device_uuid, source: Invitationable::Invitation::SOURCE[:phone]

          @advisor_invitation.reload
          expect(response.status).to eq(200)
          expect(@advisor_invitation.accepted?).to eq(true)
        end

        it "should accept invitation, ConsumerToConsumerInvitation", focus: true do
          consumer_to_consumer_invitation_prepare

          @invitation = FactoryGirl.create(:consumer_to_consumer_invitation, :email => @user.email, :phone => @user.phone, created_by_user: @inviter_user, group_user: @inviter_group_user)

          expect(@invitation.pending?).to eq(true)
          post :accept, :format => :json, id: @invitation.id, group_user_id: @invited_group_user.id, source: Invitationable::Invitation::SOURCE[:phone], :device_uuid => @device.device_uuid

          @invitation.reload

          expect(response.status).to eq(200)
          expect(@invitation.accepted?).to eq(true)
        end

        it "should accept invitation with group_user_label, ConsumerToConsumerInvitation" do
          consumer_to_consumer_invitation_prepare

          @invitation = FactoryGirl.create(:consumer_to_consumer_invitation, :email => @user.email, :phone => @user.phone, created_by_user: @inviter_user, group_user: @inviter_group_user)

          expect(@invitation.pending?).to eq(true)
          post :accept, :format => :json, id: @invitation.id, group_user_label: @inviter_group_user.label, source: Invitationable::Invitation::SOURCE[:phone], :device_uuid => @device.device_uuid

          @invitation.reload
          expect(response.status).to eq(200)
          expect(@invitation.accepted?).to eq(true)
        end
      end
    end

    context "#reject" do
      context "source: email" do
        it "should reject invitation, AdvisorToConsumerInvitation" do
          expect(@advisor_invitation.pending?).to eq(true)
          put :reject, :format => :json, id: @advisor_invitation.id, :device_uuid => @device.device_uuid, source: Invitationable::Invitation::SOURCE[:email]

          @advisor_invitation.reload
          expect(response.status).to eq(200)
          expect(@advisor_invitation.rejected?).to eq(true)
        end

        it "should reject invitation, ConsumerToConsumerInvitation" do
          expect(@consumer_invitation.pending?).to eq(true)
          put :reject, :format => :json, id: @consumer_invitation.id, :device_uuid => @device.device_uuid, source: Invitationable::Invitation::SOURCE[:email]

          @consumer_invitation.reload
          expect(response.status).to eq(200)
          expect(@consumer_invitation.rejected?).to eq(true)
        end
      end

      context "source: phone" do
        it "should reject invitation, AdvisorToConsumerInvitation" do
          expect(@advisor_invitation.pending?).to eq(true)
          put :reject, :format => :json, id: @advisor_invitation.id, :device_uuid => @device.device_uuid, source: Invitationable::Invitation::SOURCE[:phone]

          @advisor_invitation.reload
          expect(response.status).to eq(200)
          expect(@advisor_invitation.rejected?).to eq(true)
        end

        it "should reject invitation, ConsumerToConsumerInvitation" do
          expect(@consumer_invitation.pending?).to eq(true)
          put :reject, :format => :json, id: @consumer_invitation.id, :device_uuid => @device.device_uuid, source: Invitationable::Invitation::SOURCE[:phone]

          @consumer_invitation.reload
          expect(response.status).to eq(200)
          expect(@consumer_invitation.rejected?).to eq(true)
        end
      end
    end

    context "#cancel" do
      context "source: email" do
        it "should cancel invitation, AdvisorToConsumerInvitation" do
          expect(Invitationable::AdvisorToConsumerInvitation.count).to eq(1)
          put :cancel, :format => :json, id: @advisor_invitation.id, :device_uuid => @device.device_uuid, source: Invitationable::Invitation::SOURCE[:email]

          expect(response.status).to eq(200)
          expect(Invitationable::AdvisorToConsumerInvitation.count).to eq(0)
        end

        it "should cancel invitation, ConsumerToConsumerInvitation" do
          expect(Invitationable::ConsumerToConsumerInvitation.count).to eq(1)
          put :cancel, :format => :json, id: @consumer_invitation.id, :device_uuid => @device.device_uuid, source: Invitationable::Invitation::SOURCE[:email]

          expect(response.status).to eq(200)
          expect(Invitationable::ConsumerToConsumerInvitation.count).to eq(0)
        end
      end

      context "source: phone" do
        it "should cancel invitation, AdvisorToConsumerInvitation" do
          expect(Invitationable::AdvisorToConsumerInvitation.count).to eq(1)
          put :cancel, :format => :json, id: @advisor_invitation.id, :device_uuid => @device.device_uuid, source: Invitationable::Invitation::SOURCE[:phone]

          expect(response.status).to eq(200)
          expect(Invitationable::AdvisorToConsumerInvitation.count).to eq(0)
        end

        it "should cancel invitation, ConsumerToConsumerInvitation" do
          expect(Invitationable::ConsumerToConsumerInvitation.count).to eq(1)
          put :cancel, :format => :json, id: @consumer_invitation.id, :device_uuid => @device.device_uuid, source: Invitationable::Invitation::SOURCE[:phone]

          expect(response.status).to eq(200)
          expect(Invitationable::ConsumerToConsumerInvitation.count).to eq(0)
        end
      end
    end

    context "#reinvite" do
      it 'should reinvite user, AdvisorToConsumerInvitation' do
        old_invitation = @advisor_invitation
        put :reinvite, :format => :json, id: @advisor_invitation.id, :invitation => { :phone => @advisor_invitation.phone, :email => @advisor_invitation.email, :email_invitation => 1, :text_invitation => 1, :group_user_id => @group_user.id, :invitee_type => "Consumer" }, :device_uuid => @device.device_uuid
        expect(response.status).to eq(200)
        expect(Invitationable::AdvisorToConsumerInvitation.count).to eq(1)
        invitation = Invitationable::AdvisorToConsumerInvitation.first
        expect(invitation.email).to eq(old_invitation.email)
        expect(invitation.phone).to eq(old_invitation.phone)
        expect(invitation.client).to eq(old_invitation.client)
        expect(invitation.created_by_user).to eq(old_invitation.created_by_user)
        expect(invitation.created_by_user).to eq(@advisor)
        expect(invitation.email_invitation).to eq(true)
        expect(invitation.text_invitation).to eq(true)
      end

      it 'should reinvite user, ConsumerToConsumerInvitation' do
        Invitationable::ConsumerToConsumerInvitation.delete_all
        old_invitation                 = Invitationable::ConsumerToConsumerInvitation.new(consumer_invitation_params)
        old_invitation.created_by_user = @user
        old_invitation.save
        put :reinvite, :format => :json, id: old_invitation.id, :invitation => { :phone => old_invitation.phone, :email => old_invitation.email, :email_invitation => 1, :text_invitation => 1, :group_user_id => @group_user.id, :invitee_type => "Consumer" }, :device_uuid => @device.device_uuid
        expect(response.status).to eq(200)
        expect(Invitationable::ConsumerToConsumerInvitation.count).to eq(1)
        invitation = Invitationable::ConsumerToConsumerInvitation.first
        expect(invitation.email).to eq(old_invitation.email)
        expect(invitation.phone).to eq(old_invitation.phone)
        expect(invitation.group_user).to eq(old_invitation.group_user)
        expect(invitation.created_by_user).to eq(old_invitation.created_by_user)
        expect(invitation.created_by_user).to eq(@user)
        expect(invitation.email_invitation).to eq(true)
        expect(invitation.text_invitation).to eq(true)
      end
    end
  end
end
