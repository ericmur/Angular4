require 'rails_helper'
require 'spec_helper'
require 'custom_spec_helper'

RSpec.describe GroupUsersController, :type => :controller do
  before(:each) do
    standard_group = FactoryGirl.create(:standard_group)

    load_standard_documents
    load_docyt_support
    setup_logged_in_consumer
    load_startup_keys

    @group = FactoryGirl.create(:group, { :standard_group_id => standard_group.id, :owner_id => @user.id })
  end

  it 'should create new user in the group when no email or phone is provided' do
    post :create, :format => :json, :group_user => { :name => 'Shilpa Dhir', :label => 'Spouse' }, :group_id => @group.id, :device_uuid => @device.device_uuid
    expect(response.status).to eq(200)
    expect(GroupUser.count).to eq(1)
    g_user = GroupUser.first
    expect(g_user.name).to eq("Shilpa Dhir")
    expect(g_user.email).to eq(nil)
    expect(g_user.phone).to eq(nil)
  end

  it 'should create a new user in the group when email, name and phone is provided but family user has not yet signed up' do
    post :create, :format => :json, :group_user => { :name => 'Shilpa Dhir', :label => 'Spouse', :phone => '4100010001', :email => 'shilpa@vayuum.com' }, :group_id => @group.id, :device_uuid => @device.device_uuid
    expect(response.status).to eq(200)
    expect(GroupUser.count).to eq(1)
    g_user = GroupUser.first
    expect(g_user.name).to eq("Shilpa Dhir")
    expect(g_user.email).to eq('shilpa@vayuum.com')
    expect(g_user.phone).to eq('4100010001')
  end

  it 'should give an error when trying to add an existing user to the same group' do
    group_user = FactoryGirl.create(:group_user, :email => 'shilpa@vayuum.com', :phone => '4134567890', :user => nil, :group => @group)
    post :create, :format => :json, :group_user => { :name => group_user.name, :label => 'Spouse', :phone => group_user.phone, :email => group_user.email }, :group_id => @group.id, :device_uuid => @device.device_uuid
    expect(response.status).to eq(406)
    expect(GroupUser.count).to eq(1)
  end

  it 'should ignore name, email, phone if user_id is provided' do
    user = FactoryGirl.create(:consumer, :email => 'shilpa@vayuum.com')
    post :create, :format => :json, :group_user => { :name => 'Shilpa Dhir', :label => 'Spouse', :phone => '4100010001', :email => 'shilpa@vayuum.com' }, :group_id => @group.id, :device_uuid => @device.device_uuid
    expect(response.status).to eq(200)
    expect(GroupUser.count).to eq(1)
    g_user = GroupUser.first
    expect(g_user.name).to eq('Shilpa Dhir')
    expect(g_user.email).to eq('shilpa@vayuum.com')
    expect(g_user.phone).to eq('4100010001')

    put :set_user, :format => :json, :id => g_user.id, :group_user => { :user_id => user.id }, :device_uuid => @device.device_uuid
  end

  it 'should successfully set the ownership for a group_user account in the group (and clear all user attributes from group_user) provided it is not owned by any user yet' do
    post :create, :format => :json, :group_user => { :name => 'Shilpa Dhir', :email => 'shilpa@vayuum.com', :phone => '14136874000', :label => 'Spouse' }, :group_id => @group.id, :device_uuid => @device.device_uuid
    expect(response.status).to eq(200)
    expect(GroupUser.count).to eq(1)
    g_user = GroupUser.first
    expect(g_user.name).not_to eq(nil)
    expect(g_user.email).not_to eq(nil)
    expect(g_user.phone).not_to eq(nil)
    expect(g_user.phone_normalized).not_to eq(nil)

    expect(g_user.user_id).to eq(nil)
    user = FactoryGirl.create(:consumer, :email => 'shilpa@vayuum.com')
    put :set_user, :format => :json, :group_user => { :user_id => user.id }, :id => g_user.id, :password_hash => @hsh, :device_uuid => @device.device_uuid
    g_user.reload
    expect(g_user.user_id).to eq(user.id)
    expect(g_user.name).to eq(nil)
    expect(g_user.email).to eq(nil)
    expect(g_user.phone).to eq(nil)
    expect(g_user.phone_normalized).to eq(nil)
  end

  it 'should not allow setting ownership for a group_user to a random user when
it is already owned by another user' do
    post :create, :format => :json, :group_user => { :name => 'Shilpa Dhir', :email => 'shilpa@vayuum.com', :phone => '14136874000', :label => 'Spouse' }, :group_id => @group.id, :device_uuid => @device.device_uuid
    expect(response.status).to eq(200)
    expect(GroupUser.count).to eq(1)
    g_user = GroupUser.first

    expect(g_user.user_id).to eq(nil)
    user = FactoryGirl.create(:consumer, :email => 'shilpa@vayuum.com')
    put :set_user, :format => :json, :group_user => { :user_id => user.id }, :id => g_user.id, :password_hash => @hsh, :device_uuid => @device.device_uuid
    g_user.reload
    expect(g_user.user_id).to eq(user.id)

    user2 = FactoryGirl.create(:consumer, :email => 'tedi@vayuum.com')
    put :set_user, :format => :json, :group_user => { :user_id => user2.id }, :id => g_user.id, :password_hash => @hsh, :device_uuid => @device.device_uuid
    g_user.reload
    expect(response.status).to eq(406)
    res_json = JSON.parse(response.body)
    expect(res_json["errors"].first).to match(/Already assigned/i)
    expect(GroupUser.count).to eq(1)
    expect(g_user.user_id).to eq(user.id)
  end

  it 'should not allow setting ownership for a group_user to another user when that other user and the group_user both already have some documents' do
    post :create, :format => :json, :group_user => { :name => 'Shilpa Dhir', :email => 'shilpa@vayuum.com', :phone => '14136874000', :label => 'Spouse' }, :group_id => @group.id, :device_uuid => @device.device_uuid
    expect(response.status).to eq(200)
    expect(GroupUser.count).to eq(1)
    g_user = GroupUser.first

    sf = StandardFolder.where(:name => 'Personal', :category => true).first
    sbd = sf.standard_folder_standard_documents.where(:standard_base_documents => { :name => 'Drivers License' }).joins(:standard_base_document).first.standard_base_document
    Rails.stub(:user_password_hash) { @hsh }
    doc_owner = FactoryGirl.build(:document_owner, :owner => g_user)
    doc = FactoryGirl.create(:document, :standard_document_id => sbd.id, :document_owners => [doc_owner], :consumer_id => @user.id)

    expect(g_user.user_id).to eq(nil)
    user_pin = '123454'
    user = FactoryGirl.create(:consumer, :email => 'shilpa@vayuum.com', :pin => user_pin, :pin_confirmation => user_pin)
    expect(response.status).to eq(200)

    setup_logged_in_consumer(user, user_pin)
    Rails.stub(:user_password_hash) { @hsh }
    doc_owner = FactoryGirl.build(:document_owner, :owner => user)
    doc = FactoryGirl.create(:document, :standard_document_id => sbd.id, :consumer_id => user.id, :document_owners => [doc_owner])
    expect(response.status).to eq(200)

    setup_logged_in_consumer(@user, @user_pin)
    Rails.stub(:user_password_hash) { @hsh }
    put :set_user, :format => :json, :group_user => { :user_id => user.id }, :id => g_user.id, :password_hash => @hsh, :device_uuid => @device.device_uuid
    g_user.reload
    expect(response.status).to eq(406)
    res_json = JSON.parse(response.body)
    expect(res_json["errors"].first).to match(/already have documents/i)
  end

  it 'should successfully create document access requests for new user when group_user ownership is transferred to that user and group_user has documents but the other user account doesnt yet' do
    post :create, :format => :json, :group_user => { :name => 'Shilpa Dhir', :email => 'shilpa@vayuum.com', :phone => '14136874000', :label => 'Spouse' }, :group_id => @group.id, :device_uuid => @device.device_uuid
    expect(response.status).to eq(200)
    expect(GroupUser.count).to eq(1)
    g_user = GroupUser.first

    sf = StandardFolder.where(:name => 'Personal', :category => true).first
    sbd = sf.standard_folder_standard_documents.where(:standard_base_documents => { :name => 'Drivers License' }).joins(:standard_base_document).first.standard_base_document
    Rails.stub(:user_password_hash) { @hsh }
    doc_owner = FactoryGirl.build(:document_owner, :owner => g_user)
    doc = FactoryGirl.create(:document, :standard_document_id => sbd.id, :document_owners => [doc_owner], :consumer_id => @user.id)

    expect(g_user.user_id).to eq(nil)
    user_pin = '123454'
    user = FactoryGirl.create(:consumer, :email => 'shilpa@vayuum.com', :pin => user_pin, :pin_confirmation => user_pin)
    expect(response.status).to eq(200)

    symm_key = doc.symmetric_keys.for_user_access(user.id).first
    expect(symm_key).to eq(nil)
    put :set_user, :format => :json, :group_user => { :user_id => user.id }, :id => g_user.id, :password_hash => @hsh, :device_uuid => @device.device_uuid
    g_user.reload
    expect(response.status).to eq(200)
    res_json = JSON.parse(response.body)
    symm_key = doc.symmetric_keys.for_user_access(user.id).first
    expect(symm_key).to eq(nil)
    expect(doc.document_access_requests.first).not_to eq(nil)
  end

  it 'should successfully transfer the ownership of group_user to user when user has documents but group_user doesnt; no new keys are created' do
    post :create, :format => :json, :group_user => { :name => 'Shilpa Dhir', :email => 'shilpa@vayuum.com', :phone => '14136874000', :label => 'Spouse' }, :group_id => @group.id, :device_uuid => @device.device_uuid
    expect(response.status).to eq(200)
    expect(GroupUser.count).to eq(1)
    g_user = GroupUser.first
    expect(g_user.user_id).to eq(nil)

    user_pin = '123454'
    user = FactoryGirl.create(:consumer, :email => 'shilpa@vayuum.com', :pin => user_pin, :pin_confirmation => user_pin)
    expect(response.status).to eq(200)

    sf = StandardFolder.where(:name => 'Personal', :category => true).first
    sbd = sf.standard_folder_standard_documents.where(:standard_base_documents => { :name => 'Drivers License' }).joins(:standard_base_document).first.standard_base_document
    setup_logged_in_consumer(user, user_pin)
    Rails.stub(:user_password_hash) { @hsh }
    doc_owner = FactoryGirl.build(:document_owner, :owner => user)
    doc = FactoryGirl.create(:document, :standard_document_id => sbd.id, :consumer_id => user.id, :cloud_service_full_path => nil, :document_owners => [doc_owner])
    expect(response.status).to eq(200)

    expect(SymmetricKey.count).to eq(1) # user's
    symm_key = SymmetricKey.first
    setup_logged_in_consumer(@user, @user_pin)
    Rails.stub(:user_password_hash) { @hsh }
    put :set_user, :format => :json, :group_user => { :user_id => user.id }, :id => g_user.id, :password_hash => @hsh, :device_uuid => @device.device_uuid
    g_user.reload
    expect(response.status).to eq(200)
    res_json = JSON.parse(response.body)
    expect(g_user.user_id).to eq(user.id)
    expect(SymmetricKey.count).to eq(1) # user's
    expect(SymmetricKey.first.key_encrypted).to eq(symm_key.key_encrypted)
    expect(SymmetricKey.first.created_for_user_id).to eq(user.id)
  end

  context "group_user_advisor" do
    it 'should successfully share with advisor' do
      @advisor = FactoryGirl.create(:advisor)
      @client = Client.create(advisor_id: @advisor.id, consumer_id: @user.id)
      @group_user = FactoryGirl.create(:group_user, group: @group, structure_type: GroupUser::FOLDER)

      put :share_with_advisor, format: :json, device_uuid: @device.device_uuid, id: @group_user.id, advisor_id: @advisor.id
      expect(response.status).to eq(200)

      expect(@advisor.group_users.count).to eq(1)
    end

    it 'should successfully revoke share from advisor' do
      @advisor = FactoryGirl.create(:advisor)
      @client = Client.create(advisor_id: @advisor.id, consumer_id: @user.id)
      @group_user = FactoryGirl.create(:group_user, group: @group, structure_type: GroupUser::FOLDER)

      @group_user.share_with_advisor(@advisor)
      expect(@advisor.group_users.count).to eq(1)

      put :revoke_share_with_advisor, format: :json, device_uuid: @device.device_uuid, id: @group_user.id, advisor_id: @advisor.id
      expect(response.status).to eq(200)
      expect(@advisor.group_users.count).to eq(0)
    end

    it 'should not create new existing entry for same group_user' do
      @advisor = FactoryGirl.create(:advisor)
      @client = Client.create(advisor_id: @advisor.id, consumer_id: @user.id)
      @group_user = FactoryGirl.create(:group_user, group: @group, structure_type: GroupUser::FOLDER)

      put :share_with_advisor, format: :json, device_uuid: @device.device_uuid, id: @group_user.id, advisor_id: @advisor.id
      expect(response.status).to eq(200)
      expect(@advisor.group_users.count).to eq(1)

      put :share_with_advisor, format: :json, device_uuid: @device.device_uuid, id: @group_user.id, advisor_id: @advisor.id
      expect(response.status).to eq(200)
      expect(@advisor.group_users.count).to eq(1)
    end

  end
end
