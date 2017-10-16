require 'rails_helper'
require 'spec_helper'
require 'custom_spec_helper'

RSpec.describe Api::Web::V1::MessagesQuery do
  before do
    stub_request(:post, /.twilio.com/).to_return(status: 200)
    allow(TwilioClient).to receive_message_chain("get_instance.account.messages.create") { true }
    load_standard_documents
    load_docyt_support
    create_list(:message, 20, :web, chat: chat, sender: [advisor, client.user].sample)
  end

  let!(:message_query) { Api::Web::V1::MessagesQuery }

  let!(:chat)     { create(:chat) }
  let!(:client)   { create(:client, :connected, advisor: advisor) }
  let!(:advisor)  { create(:advisor, standard_category: StandardCategory.first) }

  let!(:fictitious_text) { Faker::Lorem.sentence }

  context "#search_messages" do
    it "should return list of found messages" do
      chat.chats_users_relations.create(chatable: advisor)
      chat.chats_users_relations.create(chatable: client.user)

      message = Messagable::Message.all.sample
      found_mesages = message_query.new(advisor, { chat_id: chat.id, search_phrase: message.text }).search_messages

      expect(found_mesages.first.id).to eq(message.id)
      expect(found_mesages.first.text).to eq(message.text)
    end

    it "should return empty list of found messages" do
      found_mesages = message_query.new(advisor, { chat_id: chat.id, search_phrase: fictitious_text }).search_messages

      expect(found_mesages.size).to eq(0)
    end
  end

  context '#get_messages' do
    let!(:last_message) { Messagable::Message.last }

    it 'should return ordered last n messages' do
      messages = message_query.new(advisor, { chat_id: chat.id, per_page: 10 }).get_messages

      expect(messages.size).to eq(10)
    end

    it 'should return ordered last n messages with id less than specyfic id' do
      messages = message_query.new(advisor, { chat_id: chat.id, from_message_id: last_message.id }).get_messages
      messages_ids = messages.map { |message| message.id }

      expect(messages_ids.size).to eq(19)
      expect(chat.messages.size).to eq(20)
      expect(messages_ids.include?(last_message.id)).to be_falsey
    end
  end

  context '#get_chat' do
    it 'should return chat' do
      query  = message_query.new(advisor, { chat_id: chat.id })
      chat_result = query.get_chat

      expect(chat_result.id).to eq(chat.id)
    end
  end

end
