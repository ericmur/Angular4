require 'rails_helper'
require 'spec_helper'
require 'custom_spec_helper'

RSpec.describe User, :type => :model do
  before(:each) do
    stub_request(:any, /.*twilio.com.*/).to_return(status: 200)
    allow(TwilioClient).to receive_message_chain('get_instance.account.messages.create')
    stub_docyt_support_creation
  end
  
  it 'should expect only valid emails' do 
    consumer = User.new
    consumer.email = 'tedikmnss.net'
    consumer.pin = '123456'
    consumer.pin_confirmation = '123456'
    consumer.phone = '4136874800'
    consumer.app_type = User::MOBILE_APP

    expect(consumer.save).to eq(false)
    expect(consumer.errors.full_messages).to eq(["Email is invalid"])
  end

  it 'should require valid pin confirmation on create' do 
    consumer = User.new
    consumer.email = 'tedi@kmnss.net'
    consumer.phone = '4136874800'
    consumer.pin = '123456'
    consumer.pin_confirmation = '123456'
    consumer.app_type = User::MOBILE_APP
    
    expect(consumer.save).to eq(true)
    expect(consumer.errors.empty?).to eq(true)
  end

  it 'should require pin confirmation on create' do
    consumer = User.new
    consumer.email = 'tedi@kmnss.net'
    consumer.pin = '123456'
    consumer.phone = '4136874870'
    consumer.app_type = User::MOBILE_APP

    expect(consumer.save).to eq(false)
    expect(consumer.errors.full_messages).to eq(["Pin confirmation can't be blank"])
  end

  it 'should not require pin confirmation when update' do 
    consumer = User.new
    consumer.email = 'tedi@kmnss.net'
    consumer.phone = '4136874800'
    consumer.pin = '123456'
    consumer.pin_confirmation = '123456'
    consumer.app_type = User::MOBILE_APP
    consumer.save

    consumer = User.find(consumer.id)

    consumer.phone = '4136874800'
    expect(consumer.pin).to eq(nil)
    expect(consumer.pin_confirmation).to eq(nil)

    expect(consumer.save).to eq(true)
    expect(consumer.errors.empty?).to eq(true)
  end

end
