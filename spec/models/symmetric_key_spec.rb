require 'rails_helper'
require 'spec_helper'
require 'custom_spec_helper'
require 's3'

RSpec.describe SymmetricKey, :type => :model do
  before(:each) do 
    load_startup_keys
    stub_docyt_support_creation
  end

  it 'should clear the key attribute once the encrypted key is saved' do 
    encrypt = S3::DataEncryption.new
    user1_pin = '123456'
    user1 = FactoryGirl.create(:consumer, :email => 'sugam@vayuum.com', :pin => user1_pin, :pin_confirmation => user1_pin)

    Rails.stub(:user_password_hash) { user1.password_hash(user1_pin) }
    
    key1 = FactoryGirl.create(:symmetric_key, :created_by_user => user1, :created_for_user => user1, :key => encrypt.encryption_key)
    expect(key1.key).to eq(nil)
  end

  it 'has a method decrypt_key which decrypts the key correctly' do 
    encrypt = S3::DataEncryption.new
    user1_pin = '123456'
    user2_pin = '456789'
    user1 = FactoryGirl.create(:consumer, :email => 'sugam@vayuum.com', :pin => user1_pin, :pin_confirmation => user1_pin, app_type: User::MOBILE_APP)
    user2 = FactoryGirl.create(:consumer, :email => 'sid@vayuum.com', :pin => user2_pin, :pin_confirmation => user2_pin, app_type: User::MOBILE_APP)
    key1 = FactoryGirl.create(:symmetric_key, :created_by_user => user1, :created_for_user => user2, :key => encrypt.encryption_key)
    
    Rails.stub(:user_password_hash) { user2.password_hash(user2_pin) }
    Rails.stub(:app_type) { User::MOBILE_APP }

    key1.key = encrypt.encryption_key
    key1.save!
    expect(encrypt.encryption_key).to eq(key1.decrypt_key)

    Rails.stub(:user_password_hash) { user1.password_hash(user1_pin) }
    key2 = FactoryGirl.create(:symmetric_key, :created_by_user => user1, :created_for_user => user1, :key => encrypt.encryption_key)
    expect(encrypt.encryption_key).to eq(key2.decrypt_key)
  end

end
