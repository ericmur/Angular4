require 'rails_helper'
require 'spec_helper'
require 'custom_spec_helper'

RSpec.describe Notification, type: :model do
  before(:each) do
    stub_request(:any, /.*twilio.com.*/).to_return(status: 200)
    allow(TwilioClient).to receive_message_chain('get_instance.account.messages.create')
    stub_docyt_support_creation
    @group = FactoryGirl.create(:group)
    @sender = FactoryGirl.create(:consumer)
    @recipient = FactoryGirl.create(:consumer)
  end

  it 'should successfully create notification without sender' do
    @notification = FactoryGirl.create(:notification, sender: nil, recipient: @recipient, message: Faker::Lorem.word, notification_type: Notification.notification_types[:auto_categorization])
    expect(Notification.count).to eq(1)
    expect(@notification.sender).to eq(nil)
    expect(@notification.recipient_id).to eq(@recipient.id)
    expect(@recipient.notifications.count).to eq(1)
    expect(Notification.notification_types[@notification.notification_type]).to eq(Notification.notification_types[:auto_categorization])
  end

  it 'should successfully create notification with sender' do
    @notification = FactoryGirl.create(:notification, sender: @sender, recipient: @recipient, message: Faker::Lorem.word, notification_type: Notification.notification_types[:auto_categorization])

    expect(Notification.count).to eq(1)
    expect(@notification.recipient_id).to eq(@recipient.id)
    expect(@notification.sender_id).to eq(@sender.id)
    expect(@recipient.notifications.count).to eq(1)
    expect(Notification.notification_types[@notification.notification_type]).to eq(Notification.notification_types[:auto_categorization])
  end

  it 'should accept document as notification object' do
    document_owner = FactoryGirl.build(:document_owner, :owner => @sender)
    document = FactoryGirl.create(:document, :consumer_id => @sender.id, :document_owners => [document_owner], :cloud_service_full_path => nil)
    @notification = FactoryGirl.create(:notification, sender: @sender, recipient: @recipient, notifiable: document, message: Faker::Lorem.word, notification_type: Notification.notification_types[:document_expiring])    
  end

  it 'should mark as read' do
    @notification = FactoryGirl.create(:notification, sender: @sender, recipient: @recipient, message: Faker::Lorem.word, notification_type: Notification.notification_types[:auto_categorization])
    @notification.mark_as_read

    expect(@notification.unread).to eq(false)
  end

end
