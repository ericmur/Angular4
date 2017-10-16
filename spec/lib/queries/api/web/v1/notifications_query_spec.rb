require 'rails_helper'
require 'spec_helper'
require 'custom_spec_helper'

RSpec.describe Api::Web::V1::NotificationsQuery do
  before do
    load_standard_documents
    load_docyt_support
    allow_any_instance_of(Document).to receive(:business_document?).and_return(true)
  end

  let!(:query)              { Api::Web::V1::NotificationsQuery }
  let!(:advisor)            { create(:advisor, :with_fullname) }
  let!(:standard_document)  { create(:standard_document) }

  let!(:document) do
    stub_request(:post, /.twilio.com/).to_return(status: 200)
    allow(TwilioClient).to receive_message_chain("get_instance.account.messages.create") { true }
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

  context 'get unread notifications' do
    it 'should return unread notifications' do
      notifications = query.new(advisor, {}).get_unread_notifications

      expect(notifications.size).to eq(1)
      expect(notifications).to include(unread_notification)
    end

    it 'should not return read notifications' do
      unread_notification.mark_as_read
      notifications = query.new(advisor, {}).get_unread_notifications

      expect(notifications.size).to eq(0)
      expect(notifications).not_to include(read_notification)
    end

    it 'should mark as read with no param' do
      expect{ query.new(advisor, {}).get_unread_notifications }.to change{ advisor.notifications.unread.size }.by(-1)
    end

    it 'should not mark as read with false param' do
      expect{ query.new(advisor, {}).get_unread_notifications(false) }.not_to change{ advisor.notifications.unread.size }
    end
  end
end
