require 'rails_helper'
require 'custom_spec_helper'

RSpec.describe Client, type: :model do
  before do
    load_standard_documents
    load_docyt_support
  end

  context 'Associations' do
    it { is_expected.to belong_to(:consumer) }
    it { is_expected.to belong_to(:advisor) }

    it { is_expected.to have_one(:avatar).dependent(:destroy) }

    it { is_expected.to have_many(:user_folder_settings).dependent(:destroy) }
    it { is_expected.to have_many(:chats_users_relations).dependent(:destroy) }
    it { is_expected.to have_many(:document_ownerships).class_name(DocumentOwner.name.to_s).dependent(:destroy) }
    it { is_expected.to have_many(:standard_base_document_ownerships).class_name(StandardBaseDocumentOwner.name.to_s).dependent(:destroy) }

    it { is_expected.to have_many(:invitations)
          .class_name(Invitationable::AdvisorToConsumerInvitation.name.to_s)
          .with_foreign_key('client_id')
          .dependent(:destroy)
        }
  end

  context 'Validations' do
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_presence_of(:advisor_id) }
  end

  context '#last_message_in_client_chat' do
    let!(:connected_client)   { create(:client, :connected) }
    let!(:unconnected_client) { create(:client) }

    it 'should return created_at for last message from chat client connected if chat have any message' do
      chat = Api::Web::V1::ChatsManager.new(connected_client.advisor, [connected_client.consumer]).find_or_create_with_users
      create_list(:message, 10, :web, chat: chat)

      last_message = chat.messages.last
      expect(last_message.created_at).to eq(connected_client.last_message_in_client_chat)
    end

    it 'should return nil if chat of connected client not have any message' do
      chat = Api::Web::V1::ChatsManager.new(connected_client.advisor, [connected_client.consumer]).find_or_create_with_users

      expect(connected_client.last_message_in_client_chat).to be_nil
    end

    it 'should return nil if not connected client' do
      expect(unconnected_client.last_message_in_client_chat).to be_nil
    end
  end

  context '#owner_birthday' do
    let!(:birthday)           { Faker::Date.forward(7) }
    let!(:connected_client)   { create(:client, consumer: create(:consumer, birthday: birthday)) }
    let!(:unconnected_client) { create(:client) }

    it 'should return birthday for connected client' do
      result = connected_client.owner_birthday

      expect(result).not_to be_nil
      expect(result).to eq(birthday)
    end

    it 'should not return birthday for unconnected client' do
      result = unconnected_client.owner_birthday

      expect(result).to be_nil
    end
  end
end
