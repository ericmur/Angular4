require 'rails_helper'
require 'spec_helper'
require 'custom_spec_helper'
require 'encryption'

describe UsersController do
  before(:each) do
    load_standard_documents
    load_docyt_support
    load_standard_groups
  end

  it 'should successfully create a user with email/pin/pin_confirmation' do
    post :create, { :format => 'json', :user => { :email => 'sugam@test.com', :pin => '123456', :pin_confirmation => '123456', phone: "413-687-0070" }}
    password_hash = Encryption::MD5Digest.new.digest_base64('123456')
    json_res = JSON.parse(response.body)
    user = User.where(:email => 'sugam@test.com').first
    expect(json_res["consumer"]["id"]).to eq(user.id)
    expect(json_res["consumer"]["email"]).to eq(user.email)
    expect(json_res["consumer"]["phone_normalized"]).to eq(user.phone_normalized)
    expect(json_res["consumer"]["password_hash"]).to eq(nil)
    expect(response.status).to eq(200)
    u=User.where(:email => 'sugam@test.com').first
    n = User.count
    expect(n).to equal(2) #Including one advisor from load_docyt_support
    expect(u.email).to eq('sugam@test.com')
    expect(u.pin).to equal(nil)

    expect(u.referral_code).not_to eq(nil)
    expect(u.referral_code.code).not_to eq(nil)

    [u.private_key, u.public_key, u.salt, u.encrypted_pin].each do |field|
      expect(field).not_to equal(nil)
      expect(field).not_to eq('')
    end
  end

  it 'should successfully create a user and send sms with code for phone validation' do
    ENV['WORK_OFFLINE'] = nil

    messages = double()
    allow(messages).to receive(:create)
    account = double()
    allow(account).to receive(:messages) { messages }
    twilio_obj = double()
    allow(twilio_obj).to receive(:account) { account }
    expect(TwilioClient).to receive(:get_instance) { twilio_obj }.once

    post :create, { :format => 'json', :user => { :email => 'sugam@test.com', :pin => '123456', :pin_confirmation => '123456', phone: "413-687-0070" }}
    json_res = JSON.parse(response.body)
    user = User.where(:email => 'sugam@test.com').first
    expect(json_res["consumer"]["id"]).to eq(user.id)
    expect(json_res["consumer"]["email"]).to eq(user.email)
    expect(json_res["consumer"]["phone_normalized"]).to eq(user.phone_normalized)
    expect(json_res["consumer"]["password_hash"]).to eq(nil)
    expect(response.status).to eq(200)
  end

  it 'should successfully send a sms with code for forgot your pin' do
    ENV['WORK_OFFLINE'] = nil

    messages = double()
    allow(messages).to receive(:create)
    account = double()
    allow(account).to receive(:messages) { messages }
    twilio_obj = double()
    allow(twilio_obj).to receive(:account) { account }
    FactoryGirl.create(:consumer, { :email => 'sugam@test.com', :phone => '413-687-4870'})
    expect(TwilioClient).to receive(:get_instance) { twilio_obj }.once

    post :forgot_pin, { :format => 'json', :email => 'sugam@test.com', :phone => '413-687-4870' }
    json_res = JSON.parse(response.body)
    user = User.where(:email => 'sugam@test.com').first
    expect(response.status).to eq(200)
  end

  it 'should not create a user when invalid email is provided' do
    post :create, { :format => 'json', :user => { :email => 'sugamtest.com', :pin => '123456', :pin_confirmation => '123456', phone: "413-687-0070" }}
    errors_json = JSON.parse(response.body)
    expect(errors_json['errors'].first).to match(/Email .* invalid/i)
    expect(response.status).to eq(406)
    n = User.count
    expect(n).to equal(1) #1 for DocytSupport as Advisor
  end

  it 'should not set any other parameter via form other than email, pin, pin_confirmation upon user creation' do
    dummy_private_key = 'asdfs'
    dummy_public_key = 'asdfasfdasfd'
    dummy_salt = 'asfd'
    dummy_encrypted_pin = 'asffasdfasfdfasdfasfd'
    dummy_phone = '4136874880'
    dummy_phone_normalized = '413-687-4870'
    post :create, { :format => 'json', :user => { :email => 'sugam@test.com', :pin => '123456', :pin_confirmation => '123456', :private_key => dummy_private_key, :public_key => dummy_public_key, :salt => dummy_salt, :encrypted_pin => dummy_encrypted_pin, :phone => dummy_phone, :phone_normalized => dummy_phone_normalized }}
    expect(response.status).to eq(200)
    u=User.where(:email => 'sugam@test.com').first
    n = User.count
    expect(n).to equal(2) #2 because of DocytSupport as Advisor
    expect(u.email).to eq('sugam@test.com')
    expect(u.pin).to equal(nil)
    [[u.private_key, dummy_private_key], [u.public_key, dummy_public_key], [u.salt, dummy_salt], [u.encrypted_pin, dummy_encrypted_pin]].each do |field, dummy_val|
      expect(field).not_to eq(dummy_val)
    end
  end
end
