require 'rails_helper'
require 'spec_helper'
require 'custom_spec_helper'
require 's3'

RSpec.describe Invitationable::ConsumerToConsumerInvitation, type: :model do
  before do
    ConsumerAccountType.load
    load_standard_documents
    load_docyt_support
  end

  before(:each) do
    Faker::Config.locale = 'en-US'
    stub_docyt_support_creation
    @inviter_user = FactoryGirl.create(:consumer, first_name: Faker::Name.first_name, last_name: Faker::Name.last_name, consumer_account_type_id: ConsumerAccountType.first.id)
    @inviter_user = verify_user_email(@inviter_user)
  end

  context "Associations" do
    it { is_expected.to belong_to(:group_user) }
  end

  describe "Invitation without group user" do
    it 'should successfully create without group user' do
      FactoryGirl.create(:consumer_to_consumer_invitation, :with_email_and_phone, created_by_user: @inviter_user)
    end

    it 'should successfully generate random token' do
      @invitation = FactoryGirl.create(:consumer_to_consumer_invitation, :with_email_and_phone,created_by_user: @inviter_user)
      @invitation2 = FactoryGirl.create(:consumer_to_consumer_invitation, email: 'sid@docyt.com', phone: '4134567891', created_by_user: @inviter_user)
      expect(@invitation.token).not_to eq(nil)
      expect(@invitation2.token).not_to eq(nil)
      expect(@invitation.token).not_to eq(@invitation2.token)
    end

    it 'should require full name of user' do
      @inviter_user2 = FactoryGirl.create(:consumer, first_name: nil, last_name: nil)
      @inviter_user2 = verify_user_email(@inviter_user2)
      expect {
        FactoryGirl.create(:consumer_to_consumer_invitation, :with_email_and_phone, created_by_user: @inviter_user2)
      }.to raise_error(ActiveRecord::RecordInvalid, /#{I18n.t('errors.invitation.require_fullname')}/)
    end

    it 'should require text or email selection' do
      expect {
        FactoryGirl.create(:consumer_to_consumer_invitation, :with_email_and_phone, created_by_user: @inviter_user, text_invitation: false, email_invitation: false)
      }.to raise_error(ActiveRecord::RecordInvalid, /#{I18n.t('errors.invitation.require_type_selection')}/)
    end

    it 'should successfully create for text invitation only' do
      FactoryGirl.create(:consumer_to_consumer_invitation, :with_email_and_phone, created_by_user: @inviter_user, email_invitation: false)
    end

    it 'should successfully create for email invitation only' do
      FactoryGirl.create(:consumer_to_consumer_invitation, :with_email_and_phone, created_by_user: @inviter_user, text_invitation: false)
    end

    it 'should only sent 1 invitation per email' do
      FactoryGirl.create(:consumer_to_consumer_invitation, email: 'sugam@docyt.com', phone: '4134567891', created_by_user: @inviter_user)
      expect {
        FactoryGirl.create(:consumer_to_consumer_invitation, email: 'sugam@docyt.com', phone: '4134567890', created_by_user: @inviter_user)
      }.to raise_error(ActiveRecord::RecordInvalid, /Invitation already sent to that email/)
    end

    it 'should only sent 1 invitation per phone' do
      FactoryGirl.create(:consumer_to_consumer_invitation, email: 'sugam@docyt.com', phone: '4134567891', created_by_user: @inviter_user)
      expect {
        FactoryGirl.create(:consumer_to_consumer_invitation, email: 'tedi@docyt.com', phone: '4134567891', created_by_user: @inviter_user)
      }.to raise_error(ActiveRecord::RecordInvalid, /Invitation already sent to that phone number/)
    end

    it 'should allow invite same person from different user' do
      @inviter_user2 = FactoryGirl.create(:consumer, first_name: "Shilpa", last_name: "Dhir")
      User.verify_email_token(@inviter_user2.email_confirmation_token)
      @inviter_user2.reload

      FactoryGirl.create(:consumer_to_consumer_invitation, email: 'sugam@docyt.com', phone: '4134567890', created_by_user: @inviter_user)
      FactoryGirl.create(:consumer_to_consumer_invitation, email: 'sugam@docyt.com', phone: '4134567890', created_by_user: @inviter_user2)
    end
  end

  describe 'Invitation with group user' do
    before(:each) do
      @inviter_group = FactoryGirl.create(:group, owner_id: @inviter_user.id)
      @inviter_group_user = FactoryGirl.create(:group_user, :email => Faker::Internet.email, :phone => FactoryGirl.generate(:phone), :user => nil, :group => @inviter_group)
    end

    it 'should save invitation for group user' do
      @invitation = FactoryGirl.create(:consumer_to_consumer_invitation, created_by_user: @inviter_user, group_user: @inviter_group_user)
      expect(@invitation.group_user.id).to eq(@inviter_group_user.id)
    end

    it 'should update group user email and phone' do
      invitation_email = Faker::Internet.email
      invitation_phone = FactoryGirl.generate(:phone)
      @invitation = FactoryGirl.create(:consumer_to_consumer_invitation, email: invitation_email, phone: invitation_phone, created_by_user: @inviter_user, group_user: @inviter_group_user)

      @inviter_group_user.reload
      expect(@inviter_group_user.email).to eq(invitation_email)
      expect(@inviter_group_user.phone).to eq(invitation_phone)
    end
  end

  describe "Accepting invitation" do
    before(:each) do
      standard_group = FactoryGirl.create(:standard_group)
      @invited_user = FactoryGirl.create(:consumer, first_name: Faker::Name.first_name, last_name: Faker::Name.last_name, consumer_account_type_id: ConsumerAccountType.first.id)
      @invited_user = verify_user_email(@invited_user)
      @invited_user_group = FactoryGirl.create(:group, owner_id: @invited_user.id, standard_group: standard_group)

      @inviter_group = FactoryGirl.create(:group, owner_id: @inviter_user.id, standard_group: standard_group)
      @inviter_group_user = FactoryGirl.create(:group_user, :email => @invited_user.email, :phone => @invited_user.phone, :user => nil, :group => @inviter_group)
      @inviter_user.reload
    end

    it 'should generate notifications' do
      @invitation = FactoryGirl.create(:consumer_to_consumer_invitation, :email => @invited_user.email, :phone => @invited_user.phone, created_by_user: @inviter_user, group_user: @inviter_group_user)

      expect(@inviter_user.notifications.count).to eq(0)
      expect(@invited_user.notifications.count).to eq(1)

      expect(@invitation.accept_invitation!(@invited_user, nil, 'Friend')).to eq(true)

      @inviter_user.reload
      expect(@inviter_user.notifications.count).to eq(1)
    end

    it 'should update state attributes' do
      @invitation = FactoryGirl.create(:consumer_to_consumer_invitation, :email => @invited_user.email, :phone => @invited_user.phone, created_by_user: @inviter_user, group_user: @inviter_group_user)

      expect(@invitation.accept_invitation!(@invited_user, nil, 'Friend')).to eq(true)

      expect(@invitation.accepted_by_user.id).to eq(@invited_user.id)
      expect(@invitation.accepted_at.present?).to eq(true)
      expect(@invitation.accepted?).to eq(true)
    end

    it 'should create new group user when only group_user label provided', focus: true do
      @invitation = FactoryGirl.create(:consumer_to_consumer_invitation, :email => @invited_user.email, :phone => @invited_user.phone, created_by_user: @inviter_user, group_user: @inviter_group_user)

      expect(@invitation.accept_invitation!(@invited_user, nil, 'Friend')).to eq(true)

      expect(@inviter_user.group_users_as_group_owner.count).to eq(1)
      expect(@invited_user.group_users_as_group_owner.count).to eq(1)
    end

    it 'should connect group_user' do
      @invitee_group_user = FactoryGirl.create(:group_user, :email => @inviter_user.email, :phone => @inviter_user.phone, :user => nil, :group => @invited_user_group)
      @invitation = FactoryGirl.create(:consumer_to_consumer_invitation, :email => @invited_user.email, :phone => @invited_user.phone, created_by_user: @inviter_user, group_user: @inviter_group_user)

      expect(@invitation.accept_invitation!(@invited_user, @invitee_group_user, nil)).to eq(true)

      expect(GroupUser.where(user_id: @inviter_user.id).count).to eq(1)
      expect(GroupUser.where(user_id: @invited_user.id).count).to eq(1)

      @invitee_group_user.reload
      @inviter_group_user.reload

      expect(@invitee_group_user.user_id).to eq(@inviter_user.id)
      expect(@inviter_group_user.user_id).to eq(@invited_user.id)
    end

    it 'should failed to accept invitation when no group_user_label or group_user_id provided' do
      @invitation = FactoryGirl.create(:consumer_to_consumer_invitation, :email => @invited_user.email, :phone => @invited_user.phone, created_by_user: @inviter_user, group_user: @inviter_group_user)

      expect(@invitation.accept_invitation!(@invited_user, nil, nil)).to eq(false)

      expect(@invitation.state).to eq('pending')
      expect(@invitation.errors.count).to eq(1)
    end

    it 'should not create group user for inviter when failed' do
      @invitation = FactoryGirl.create(:consumer_to_consumer_invitation, :email => @invited_user.email, :phone => @invited_user.phone, created_by_user: @inviter_user, group_user: @inviter_group_user)

      expect(@invitation.accept_invitation!(@invited_user, nil, nil)).to eq(false)

      expect(@inviter_user.group_users.count).to eq(0)
      expect(@invited_user.group_users_as_group_owner.count).to eq(0)
    end

    it 'should failed when invitation email/phone is not the same with invitee' do
      @invitation = FactoryGirl.create(:consumer_to_consumer_invitation, :email => @invited_user.email, :phone => @invited_user.phone, created_by_user: @inviter_user, group_user: @inviter_group_user)
      @invited_user2 = FactoryGirl.create(:consumer, first_name: Faker::Name.first_name, last_name: Faker::Name.last_name)
      User.verify_email_token(@invited_user2.email_confirmation_token)
      @invited_user2.reload

      expect(@invitation.accept_invitation!(@invited_user2, nil, 'Friend')).to eq(false)

      expect(@invitation.state).to eq('pending')
      expect(@invitation.errors.count).to eq(1)
    end
  end

  describe "Document Owner" do
    before(:each) do
      standard_group = FactoryGirl.create(:standard_group)
      @inviter_user_group = FactoryGirl.create(:group, owner_id: @inviter_user.id, standard_group: standard_group)
      @inviter_group_user = FactoryGirl.create(:group_user, group: @inviter_user_group, :user => nil, :email => Faker::Internet.email, :phone => FactoryGirl.generate(:phone))
      @document_owner = FactoryGirl.build(:document_owner, :owner => @inviter_group_user)

      @invited_user = FactoryGirl.create(:consumer, first_name: Faker::Name.first_name, last_name: Faker::Name.last_name, consumer_account_type_id: ConsumerAccountType.first.id)
      @invited_user = verify_user_email(@invited_user)
      @invited_user_group = FactoryGirl.create(:group, owner_id: @invited_user.id, standard_group: standard_group)

      consumer_pin = '123456'

      @consumer_password_hash = @invited_user.password_hash(consumer_pin)
      Rails.stub(:user_password_hash) { @consumer_password_hash }

      @vayuum_password_hash = '1234567890'
      @vayuum_private_key = File.read('spec/data/id_rsa.test-startup.vayuum.pem')
      load_startup_keys({ :password_hash => @vayuum_password_hash, :private_key => @vayuum_private_key })
    end

    def prepare_document_and_invitation
      encrypt = S3::DataEncryption.new
      S3::DataEncryption.stub(:new) { encrypt }
      allow(S3::DataEncryption).to receive(:new).and_call_original

      @document = FactoryGirl.create(:document, :consumer_id => @inviter_user.id, :document_owners => [@document_owner], :cloud_service_full_path => nil)
      expect(@document.document_owners.count).to eq(1)
      expect(@document.document_owners.first.id).to eq(@document_owner.id)
      expect(@document_owner.owner_type).to eq(GroupUser.to_s)
      expect(@document_owner.owner_id).to eq(@inviter_group_user.id)
      expect(@inviter_group_user.user_id).to eq(nil)

      expect(@inviter_group_user.document_ownerships.first.document_id).to eq(@document.id)

      @invitation = FactoryGirl.create(:consumer_to_consumer_invitation, :email => @invited_user.email, :phone => @invited_user.phone, created_by_user: @inviter_user, group_user: @inviter_group_user)
      expect(@invitation.accept_invitation!(@invited_user, nil, 'Friend')).to eq(true)

      @document.reload
      @document_owner.reload

      expect(@inviter_group_user.user_id).to eq(@invited_user.id)

      expect(@document.document_owners.count).to eq(1)
      expect(@document.document_owners.first.id).to eq(@document_owner.id)
      expect(@document_owner.owner_type).to eq(User.to_s)
      expect(@document_owner.owner_id).to eq(@invited_user.id)
    end

    it "should set document owner to invited user" do
      prepare_document_and_invitation
    end

    it "should set document owner to group user", focus: true do
      prepare_document_and_invitation

      last_notification_count = Notification.count

      revoked_user_id = @inviter_group_user.user_id
      @inviter_group_user.unlink! { |success, message|
        expect(success).to eq(true)
      }

      # Unlinking will now destroy group user / client
      # Since: 1.1.9
      expect {
        @document_owner = DocumentOwner.find(@document_owner.id)
      }.to raise_error(ActiveRecord::RecordNotFound)

      expect(Notification.count).to eq(last_notification_count + 1)

    end

    it "should have the same number of documents" do
      prepare_document_and_invitation

      expect(@inviter_user.reload.document_ownerships.count).to eq(0)
      expect(@invited_user.reload.document_ownerships.count).to eq(1)
    end
  end
end
