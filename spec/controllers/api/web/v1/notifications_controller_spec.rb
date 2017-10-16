require 'rails_helper'
require 'spec_helper'
require 'custom_spec_helper'

describe Api::Web::V1::NotificationsController do
  before do
    stub_request(:post, /.twilio.com/).to_return(status: 200)
    allow(TwilioClient).to receive_message_chain("get_instance.account.messages.create") { true }
    load_standard_documents
    load_docyt_support
    allow_any_instance_of(Document).to receive(:business_document?).and_return(true)
  end

  let!(:advisor)            { create(:advisor, :with_fullname) }
  let!(:standard_document)  { create(:standard_document) }

  let!(:document) do
    doc = create(:document, :with_uploader_and_owner)
    doc.update(standard_document_id: standard_document.id)
    doc
  end

  let!(:unread_notification) do
    notification = Notification.new
    notification.sender = document.uploader
    notification.recipient = advisor
    notification.message = "#{document.uploader.first_name} has uploaded #{document.standard_document.name} for you."
    notification.notifiable = document
    notification.notification_type = Notification.notification_types[:new_document_sharing]
    notification.save
    notification
  end

  let!(:read_notification) do
    notification = Notification.new
    notification.sender = document.uploader
    notification.recipient = advisor
    notification.message = "#{document.uploader.first_name} has uploaded #{document.standard_document.name} for you."
    notification.notifiable = document
    notification.notification_type = Notification.notification_types[:new_document_sharing]
    notification.unread = false
    notification.save
    notification
  end

  context '#index' do
    it 'should return list of unread notifications' do
      request.headers['X-USER-TOKEN'] = advisor.authentication_token
      expect{ xhr :get, :index }.to change{ advisor.notifications.unread.size }.by(-1)

      notifications_list = JSON.parse(response.body)['notifications']

      expect(notifications_list.size).to eq(1)
      expect(response).to have_http_status(200)
    end

    it 'should not return list of read notifications' do
      unread_notification.mark_as_read
      request.headers['X-USER-TOKEN'] = advisor.authentication_token
      expect{ xhr :get, :index }.not_to change{ advisor.notifications.unread.size }

      notifications_list = JSON.parse(response.body)['notifications']

      expect(notifications_list).to eq([])
      expect(response).to have_http_status(200)
    end
  end
end
