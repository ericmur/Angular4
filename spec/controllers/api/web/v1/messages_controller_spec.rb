require 'rails_helper'
require 'spec_helper'
require 'custom_spec_helper'

describe Api::Web::V1::MessagesController do
  before do
    stub_request(:post, /.twilio.com/).to_return(status: 200)
    allow(TwilioClient).to receive_message_chain("get_instance.account.messages.create") { true }
    load_standard_documents
    load_docyt_support
  end

  let!(:message)  { create(:message, :web) }
  let!(:chat)     { message.chat }
  let!(:advisor)  { chat.chatable_users.where.not(standard_category_id: nil).first}
  let!(:consumer) { chat.chatable_users.find_by(standard_category_id: nil) }
  let!(:client)   { consumer.client_seats.find_by(advisor_id: advisor) }

  context '#index' do
    before do
      @chats_manager = instance_double("Api::Web::V1::ChatsManager")
      allow(Api::Web::V1::ChatsManager).to receive(:new).and_return(@chats_manager)
      allow(@chats_manager).to receive(:find_or_create_with_users).and_return(chat)
    end

    it 'should return messages list' do
      request.headers['X-USER-TOKEN'] = advisor.authentication_token
      xhr :get, :index, chat_id: chat.id
      messages_list = JSON.parse(response.body)['messages']

      expect(messages_list.count).to eq(1)
      expect(response).to have_http_status(200)
    end
  end

  context '#search' do
    before do
      create_list(:message, 20, :web, chat: chat, sender: [advisor, client.user].sample)
    end

    it 'should return list of found messages' do
      request.headers['X-USER-TOKEN'] = advisor.authentication_token
      xhr :get, :search, chat_id: chat.id, search_phrase: message.text
      messages_list = JSON.parse(response.body)['messages']

      expect(messages_list.count).to eq(1)
      expect(response).to have_http_status(200)
    end
  end

end
