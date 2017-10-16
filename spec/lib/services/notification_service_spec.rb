require 'rails_helper'
require 'spec_helper'
require 'custom_spec_helper'

RSpec.describe NotificationService do
  before do
    load_standard_documents('standard_base_documents_structure3.json')
    load_docyt_support('standard_base_documents_structure3.json')
  end

  let!(:service)  { NotificationService }
  let!(:chat)     { create(:chat) }
  let!(:receiver) { create(:client) }
  let!(:sender)   { create(:advisor, :with_auth_token)}
  let!(:message)  { create(:message, :web, chat: chat, sender: sender) }

  let!(:message_user)  { build(:message_user, receiver: receiver, message: message, read_at: nil) }

  context '#search_and_send_unread_notifications' do

    before(:each) do
      chat.chatable_users   << sender
      chat.chatable_clients << receiver
    end

    it 'should return count of unread message users' do
      message_user.save

      expect(Messagable::MessageUser.last.notify_at).to be_nil

      notifications = service.new
      result = notifications.search_and_send_unread_notifications

      expect(result).to eq(1)
      expect(Messagable::MessageUser.last.notify_at).not_to be_nil
    end

    it 'should return nil if there are no suitable conditions' do
      notifications = service.new
      result = notifications.search_and_send_unread_notifications

      expect(result).to be_nil
    end
  end
end
