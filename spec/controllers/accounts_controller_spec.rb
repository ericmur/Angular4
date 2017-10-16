require 'rails_helper'
require 'spec_helper'
require 'custom_spec_helper'

RSpec.describe AccountsController, :type => :controller do
  before(:each) do
    # load_standard_documents
    # load_docyt_support
    stub_docyt_support_creation
    setup_logged_in_consumer
    load_startup_keys
    load_standard_groups
  end

  it 'should render password hash upon login' do
    get :show, :format => :json, :pin => @user_pin, :device_uuid => @device.device_uuid
    expect(response.status).to eq(200)
    res_json = JSON.parse(response.body)
    u = User.first
    expect(res_json["consumer"]["password_hash"]).to eq(@hsh)
    expect(User.all.map(&:id)).to include(res_json["consumer"]["id"])
    pgp = Encryption::Pgp.new({ :password => @hsh, :private_key => @user.private_key })
    expect(res_json["consumer"]["private_key"]).to eq(pgp.unencrypted_private_key)
  end

  it 'should render error when device_uuid is not an added device yet' do
    get :show, :format => :json, :pin => @user_pin, :device_uuid => 'invalid-device-uuid'
    expect(response.status).to eq(403)
    res_json = JSON.parse(response.body)
    expect(res_json["errors"].first).to match(/Device not authorized/)
  end

  it 'should render error when no device_uuid parameter is passed' do
    get :show, :format => :json, :pin => @user_pin
    expect(response.status).to eq(403)
    res_json = JSON.parse(response.body)
    expect(res_json["errors"].first).to match(/Device not authorized/)
  end

  it 'should render error when device_uuid is added but not confirmed yet' do
    device = FactoryGirl.create(:device, :confirmed_at => nil, :user_id => @user.id)

    get :show, :format => :json, :pin => @user_pin, :device_uuid => device.device_uuid
    expect(response.status).to eq(403)
    res_json = JSON.parse(response.body)
    expect(res_json["errors"].first).to match(/Device not authorized/)
  end

  it 'should add device just once even if there are multiple calls to add it' do
    expect(@user.devices.count).to eq(1)
    new_device_uuid = 'new-device-uuid'
    put :add_device, { :format => 'json', :device => { :device_uuid => new_device_uuid } }
    expect(response.status).to eq(200)
    expect(@user.devices.count).to eq(2)

    put :add_device, { :format => 'json', :device => { :device_uuid => new_device_uuid } }
    expect(response.status).to eq(200)
    expect(@user.devices.count).to eq(2)
  end

  it 'should add a device and send sms with code and should not require any device added check for this call' do
    expect(@user.devices.count).to eq(1)

    expect_any_instance_of(TokenUtils).to receive(:send_token).once

    new_device_uuid = 'new-device-uuid'
    put :add_device, { :format => 'json', :device => { :device_uuid => new_device_uuid } }
    expect(response.status).to eq(200)
    expect(@user.devices.count).to eq(2)

    get :show, :format => :json, :pin => @user_pin, :device_uuid => new_device_uuid
    expect(response.status).to eq(403)
    res_json = JSON.parse(response.body)
    expect(res_json["errors"].first).to match(/Device not authorized/)
  end

  it 'should resend code for new device if requested' do
    @user.devices.create!(:device_uuid => 'device-uuid')

    expect_any_instance_of(Device).to receive(:resend_new_device_code).and_call_original
    expect_any_instance_of(TokenUtils).to receive(:send_token).and_call_original

    put :resend_new_device_code, { :format => 'json', :device => { :device_uuid => 'device-uuid' } }
    expect(response.status).to eq(200)

    expect(@user.devices.select { |d| d.confirmed_at }.count).to eq(1)
    expect(@user.devices.select { |d| d.confirmed_at.nil? }.count).to eq(1)
  end

  it 'should resend code for phone number if requested' do
    @user.devices.destroy_all
    @user.update_attribute(:phone_confirmed_at, nil)

    expect_any_instance_of(User).to receive(:resend_phone_confirmation_code).and_call_original
    expect_any_instance_of(TokenUtils).to receive(:send_token).and_call_original

    put :resend_phone_confirmation_code, { :format => 'json' }
    expect(response.status).to eq(200)
  end

  it 'should confirm an added device and allow access once confirmed' do
    new_device_uuid = 'new-device-uuid'
    put :add_device, { :format => 'json', :device => { :device_uuid => new_device_uuid }, :device_uuid => @user.devices.first.device_uuid }
    expect(response.status).to eq(200)
    expect(@user.devices.count).to eq(2)
    expect(@user.devices.last.confirmed_at).to eq(nil)
    put :confirm_device, { :format => 'json', :device => { :device_uuid => new_device_uuid, :token => @user.devices.last.confirmation_token }, :device_uuid => @user.devices.first.device_uuid }
    expect(response.status).to eq(200)
    expect(@user.devices.count).to eq(2)
    @user.devices.last.reload
    expect(@user.devices.last.confirmed_at).to_not eq(nil)

    get :show, :format => :json, :pin => @user_pin, :device_uuid => new_device_uuid
    expect(response.status).to eq(200)
  end

  it 'should not confirm added device on invalid token' do
    new_device_uuid = 'new-device-uuid'
    put :add_device, { :format => 'json', :device => { :device_uuid => new_device_uuid }, :device_uuid => @user.devices.first.device_uuid }
    expect(response.status).to eq(200)
    expect(@user.devices.count).to eq(2)
    expect(@user.devices.last.confirmed_at).to eq(nil)
    put :confirm_device, { :format => 'json', :device => { :device_uuid => new_device_uuid, :token => 'invalid-token' }, :device_uuid => @user.devices.first.device_uuid }
    expect(response.status).to eq(406)
    res_json = JSON.parse(response.body)
    expect(res_json["errors"].first).to match(/Invalid Code/)
    @user.devices.last.reload
    expect(@user.devices.last.confirmed_at).to eq(nil)
  end

  it 'should not confirm invalid token' do
    @user.devices.destroy_all
    @user.update_attribute(:phone_confirmed_at, nil)
    put :confirm_phone_number, :format => :json, :token => 'invalid-token', :device => 'new-device-id'
    expect(response.status).to eq(406)
    res_json = JSON.parse(response.body)
    expect(res_json["errors"].first).to match(/Invalid Code/)
  end

  it 'should confirm the phone number and add the device and allow access to account show page after' do
    @user.devices.destroy_all
    @user.update_attribute(:phone_confirmed_at, nil)
    get :show, :format => :json, :pin => @user_pin, :device => 'new-device-id'
    expect(response.status).to eq(403)
    res_json = JSON.parse(response.body)
    expect(res_json["errors"].first).to match(/Confirmed phone number/)

    expect_any_instance_of(Device).not_to receive(:send_confirmation_token)
    put :confirm_phone_number, { :format => 'json', :token => @user.phone_confirmation_token, :device_uuid => 'new-device-id' }
    expect(response.status).to eq(200)
    expect(@user.devices.count).to eq(1)
    expect(@user.devices.first.device_uuid).to eq('new-device-id')

    put :show, :format => :json, :pin => @user_pin, :device_uuid => 'new-device-id'
    expect(response.status).to eq(200)
  end

  it 'should render error when phone is not confirmed yet' do
    @user.update_attribute(:phone_confirmed_at, nil)
    get :show, :format => :json, :pin => @user_pin
    expect(response.status).to eq(403)
    res_json = JSON.parse(response.body)
    expect(res_json["errors"].first).to match(/Confirmed phone number/)
  end

  it 'should require pin' do
    get :show, :format => :json, :device_uuid => @device.device_uuid
    expect(response.status).to eq(406)
    res_json = JSON.parse(response.body)
    expect(res_json["errors"].first).to match(/Pin is required/)
  end

  it 'should allow you to change pin on a new device if private key is provided' do
    pgp = Encryption::Pgp.new({ :password => @hsh, :private_key => @user.private_key })
    put :update_pin, :format => :json, :pin => '123456', :private_key => pgp.unencrypted_private_key
    expect(response.status).to eq(200)
  end

  it 'should not allow to change pin if user is not logged in' do
    controller.stub(:doorkeeper_token) { nil }
    put :update_pin, :format => :json, :device_uuid => @device.device_uuid
    expect(response.status).to eq(401)
  end

  it 'should not allow to change pin if blank private key is provided' do
    put :update_pin, :format => :json, :device_uuid => @device.device_uuid, :pin => '1234'
    expect(response.status).to eq(406)
    res_json = JSON.parse(response.body)
    expect(res_json["errors"].first).to match(/Private key is required/)
  end

  it 'should allow to change pin when user is logged in on an existing device' do
    pgp = Encryption::Pgp.new({ :password => @hsh, :private_key => @user.private_key })
    put :update_pin, :format => :json, :device_uuid => @device.device_uuid, :pin => '1234', :private_key => pgp.unencrypted_private_key
    expect(response.status).to eq(200)
    @user.reload
    res_json = JSON.parse(response.body)


    expect(res_json['consumer']['private_key']).to eq(pgp.unencrypted_private_key)
    expect(res_json['consumer']['private_key']).to_not eq(pgp.private_key)
    expect(@user.valid_pin?('1234')).to eq(true)
  end

  context "#allow_access" do
    before do
      load_standard_documents
    end

    it 'should allow setting accessor and once set all documents should be shared with that accessor' do
      user2 = FactoryGirl.create(:consumer, :email => 'sid@vayuum.com')
      Rails.stub(:user_password_hash) { @hsh }
      sf = StandardFolder.where(:name => 'Personal', :category => true).first
      sbd = sf.standard_folder_standard_documents.where(:standard_base_documents => { :name => 'Drivers License' }).joins(:standard_base_document).first.standard_base_document
      doc_owner = FactoryGirl.build(:document_owner, :owner => @user)
      doc = FactoryGirl.create(:document, :standard_document_id => sbd.id, :consumer_id => @user.id, :cloud_service_full_path => nil, :document_owners => [doc_owner])
      expect(doc.symmetric_keys.for_user_access(@user.id).first).not_to eq(nil)
      expect(doc.symmetric_keys.for_user_access(user2.id).first).to eq(nil)
      expect(doc.symmetric_keys.count).to eq(1) # user's

      put :allow_access, :format => :json, :accessor_id => user2.id, :password_hash => @hsh, :device_uuid => @device.device_uuid
      expect(response.status).to eq(200)
      expect(UserAccess.count).to eq(1)
      expect(UserAccess.first.user_id).to eq(@user.id)
      expect(UserAccess.first.accessor_id).to eq(user2.id)
      expect(doc.symmetric_keys.count).to eq(2) # 2 users
      expect(doc.symmetric_keys.for_user_access(user2.id).first).not_to eq(nil)
    end

     it 'should not allow setting accessor when password is not provided' do
      user2 = FactoryGirl.create(:consumer, :email => 'sid@vayuum.com')
      put :allow_access, :format => :json, :accessor_id => user2.id, :device_uuid => @device.device_uuid
      expect(response.status).to eq(406)
      expect(UserAccess.count).to eq(0)
    end

    it 'should not allow setting accessor when that user has atleast 1 document and his incorrect password is provided in the API' do
      user2 = FactoryGirl.create(:consumer, :email => 'sid@vayuum.com')
      sf = StandardFolder.where(:name => 'Personal', :category => true).first
      sbd = sf.standard_folder_standard_documents.where(:standard_base_documents => { :name => 'Drivers License' }).joins(:standard_base_document).first.standard_base_document
      Rails.stub(:user_password_hash) { @hsh }
      doc_owner = FactoryGirl.build(:document_owner, :owner => @user)
      FactoryGirl.create(:document, :consumer_id => @user.id, :document_owners => [doc_owner], :standard_document_id => sbd.id)
      allow(Rails).to receive(:user_password_hash).and_call_original
      put :allow_access, :format => :json, :accessor_id => user2.id, :password_hash => '123457', :device_uuid => @device.device_uuid
      expect(response.status).to eq(406)
      expect(UserAccess.count).to eq(0)
    end

    it 'should not allow a user to give a random user access to some other users account' do
      user2 = FactoryGirl.create(:consumer, :email => 'sid@vayuum.com')
      user3 = FactoryGirl.create(:consumer, :email => 'tedi@vayuum.com')
      Rails.stub(:user_password_hash) { @hsh }
      put :allow_access, :format => :json, :accessor_id => user2.id, :user_id => user3.id, :password_hash => @hsh, :device_uuid => @device.device_uuid
      expect(response.status).to eq(200)
      expect(UserAccess.count).to eq(1)
      expect(UserAccess.first.user_id).to eq(@user.id)
      expect(UserAccess.first.accessor_id).to eq(user2.id)
    end


    it 'should successfully allow removal of a current account accessor and remove all document sharing with him' do
      user2 = FactoryGirl.create(:consumer, :email => 'sid@vayuum.com')
      Rails.stub(:user_password_hash) { @hsh }
      sf = StandardFolder.where(:name => 'Personal', :category => true).first
      sbd = sf.standard_folder_standard_documents.where(:standard_base_documents => { :name => 'Drivers License' }).joins(:standard_base_document).first.standard_base_document
      doc_owner = FactoryGirl.build(:document_owner, :owner => @user)
      doc = FactoryGirl.create(:document, :standard_document_id => sbd.id, :consumer_id => @user.id, :cloud_service_full_path => nil, :document_owners => [doc_owner])
      expect(doc.symmetric_keys.for_user_access(@user.id).first).not_to eq(nil)
      expect(doc.symmetric_keys.for_user_access(user2.id).first).to eq(nil)
      expect(doc.symmetric_keys.count).to eq(1) # user's key
      #Give Access
      put :allow_access, :format => :json, :accessor_id => user2.id, :password_hash => @hsh, :device_uuid => @device.device_uuid
      expect(response.status).to eq(200)
      expect(UserAccess.count).to eq(1)
      expect(UserAccess.first.user_id).to eq(@user.id)
      expect(UserAccess.first.accessor_id).to eq(user2.id)
      expect(doc.symmetric_keys.count).to eq(2) # 2 users
      expect(doc.symmetric_keys.for_user_access(user2.id).first).not_to eq(nil)

      #Remove Access now
      put :remove_access, :format => :json, :accessor_id => user2.id, :remove_keys => true, :password_hash => @hsh, :device_uuid => @device.device_uuid
      expect(response.status).to eq(204)
      expect(UserAccess.count).to eq(0)
      expect(doc.symmetric_keys.count).to eq(1) # user's key
      expect(doc.symmetric_keys.for_user_access(user2.id).first).to eq(nil)
    end

    it 'should successfully allow removal of a current account accessor while keeping the current document sharing with him' do
      user2 = FactoryGirl.create(:consumer, :email => 'sid@vayuum.com')
      Rails.stub(:user_password_hash) { @hsh }
      sf = StandardFolder.where(:name => 'Personal', :category => true).first
      sbd = sf.standard_folder_standard_documents.where(:standard_base_documents => { :name => 'Drivers License' }).joins(:standard_base_document).first.standard_base_document
      doc_owner = FactoryGirl.build(:document_owner, :owner => @user)
      doc = FactoryGirl.create(:document, :standard_document_id => sbd.id, :consumer_id => @user.id, :cloud_service_full_path => nil, :document_owners => [doc_owner])
      expect(doc.symmetric_keys.for_user_access(@user.id).first).not_to eq(nil)
      expect(doc.symmetric_keys.for_user_access(user2.id).first).to eq(nil)
      expect(doc.symmetric_keys.count).to eq(1) # user's key
      #Give Access
      put :allow_access, :format => :json, :accessor_id => user2.id, :password_hash => @hsh, :device_uuid => @device.device_uuid
      expect(response.status).to eq(200)
      expect(UserAccess.count).to eq(1)
      expect(UserAccess.first.user_id).to eq(@user.id)
      expect(UserAccess.first.accessor_id).to eq(user2.id)
      expect(doc.symmetric_keys.count).to eq(2) # 2 users
      expect(doc.symmetric_keys.for_user_access(user2.id).first).not_to eq(nil)

      #Remove Access now
      put :remove_access, :format => :json, :accessor_id => user2.id, :password_hash => @hsh, :device_uuid => @device.device_uuid
      expect(response.status).to eq(204)
      expect(UserAccess.count).to eq(0)
      expect(doc.symmetric_keys.count).to eq(2) # 2 users
      expect(doc.symmetric_keys.for_user_access(user2.id).first).not_to eq(nil)
    end
  end
end
