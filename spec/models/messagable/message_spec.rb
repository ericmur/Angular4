require 'rails_helper'
require 'custom_spec_helper'

describe Messagable::Message, type: :model do
  before do
    load_standard_documents
    load_docyt_support
  end

  let!(:chat)    { create(:chat) }
  let!(:client)  { create(:client, :connected) }
  let!(:message) { create(:message, :web, chat: chat, sender: client.consumer) }

  context 'Associations' do
    it { is_expected.to belong_to(:chat) }
    it { is_expected.to belong_to(:sender) }
    it { is_expected.to have_many(:message_users) }
    it { is_expected.to have_one(:chat_document) }
  end

  context 'Validations' do
    it { is_expected.to validate_presence_of(:text) }
    it { is_expected.to validate_presence_of(:chat) }
    it { is_expected.to validate_presence_of(:type) }
    it { is_expected.to validate_presence_of(:sender) }
    it { is_expected.to validate_inclusion_of(:type).in_array(Messagable::Message::MESSAGE_TYPES) }
  end

  context '#create_notifications_for_chat_users' do
    it 'should create message users' do
      chat.chatable_users << client.advisor
      chat.chatable_users << client.consumer

      expect{
        message.create_notifications_for_chat_users!
      }.to change{ Messagable::MessageUser.count }.from(0).to(1)
    end
  end

  context '#sender_name' do
    it 'should return name' do
      expect(message.sender_name).to eq(client.consumer.parsed_fullname)
    end

    it 'should return email' do
      consumer = client.consumer
      consumer.last_name  = nil
      consumer.first_name = nil
      consumer.save

      expect(message.sender_name).to eq(consumer.email)
    end
  end
end
