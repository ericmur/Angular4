require 'rails_helper'
require 'spec_helper'
require 'custom_spec_helper'

RSpec.describe NotificationsController, :type => :controller do
  before(:each) do
    # load_standard_documents
    stub_docyt_support_creation
    setup_logged_in_consumer
    load_startup_keys

    @notification = FactoryGirl.create(:notification, sender: nil, recipient: @user, message: Faker::Lorem.word, notification_type: Notification.notification_types[:auto_categorization])
  end

  it 'should return users notifications' do
    get :index, :format => :json, :device_uuid => @device.device_uuid, :password_hash => @hsh
    expect(response.status).to eq(200)
    res_json = JSON.parse(response.body)
    expect(res_json["notifications"].size).to eq(1)
    res_json["notifications"].each do |notification|
      expect(notification["recipient_id"].to_i).to eq(@user.id)
    end
  end

  it 'should mark as read' do
    expect(@notification.unread).to eq(true)
    put 'mark_as_read', format: :json, id: @notification.id, :device_uuid => @device.device_uuid
    expect(response.status).to eq(200)
    @notification.reload
    expect(@notification.unread).to eq(false)
  end
end
