require 'rails_helper'
require 'spec_helper'
require 'custom_spec_helper'

RSpec.describe Api::Web::V1::ClientsQuery do
  before do
    stub_request(:post, /.twilio.com/).to_return(status: 200)
    allow(TwilioClient).to receive_message_chain("get_instance.account.messages.create") { true }
    load_standard_documents
    load_docyt_support
    create_list(:client, 25, advisor: advisor_with_client)
  end

  let!(:client)                 { create(:client) }
  let!(:clients_query)          { Api::Web::V1::ClientsQuery }
  let!(:connected_client)       { create(:client,  :connected, advisor: advisor_with_client) }
  let!(:unconnected_client)     { create(:client,  advisor: advisor_with_client, name: Faker::Name.unique.name) }
  let!(:advisor_with_client)    { create(:advisor, :standard_category => StandardCategory.first) }
  let!(:advisor_without_client) { create(:advisor, :standard_category => StandardCategory.first) }

  context "#get_clients" do
    it "should return first page clients" do
      clients = clients_query.new(advisor_with_client, {}).get_clients

      expect(clients.count).to eq(20)
      expect(clients.ids).to include(connected_client.id)
      expect(clients.sample.advisor_id).to eq(advisor_with_client.id)
    end

    it "should return second page clients" do
      clients = clients_query.new(advisor_with_client, { page: 2 }).get_clients

      expect(clients.count).to eq(7)
      expect(clients.ids).not_to include(connected_client.id)
      expect(clients.sample.advisor_id).to eq(advisor_with_client.id)
    end

    it "should return only connected clients" do
      clients = clients_query.new(advisor_with_client, { only_connected: true }).get_clients

      expect(clients.count).to eq(1)
      expect(clients.ids).to include(connected_client.id)
      expect(clients.sample.advisor_id).to eq(advisor_with_client.id)
    end

    it "should return empty relation if advisor have no clients" do
      clients = clients_query.new(advisor_without_client, {}).get_clients

      expect(clients.count).to eq(0)
    end
  end

  context '#search_clients' do
    it 'should to find connected client by name' do
      client_name = connected_client.owner_name.split(' ').first
      clients = clients_query.new(advisor_with_client, { fulltext_search: client_name }).search_clients

      expect(clients.count).to eq(1)
      expect(clients.sample.id).to eq(connected_client.id)
    end

    it 'should to find connected client by email' do
      client_email = connected_client.owner_email
      clients = clients_query.new(advisor_with_client, { fulltext_search: client_email }).search_clients

      expect(clients.count).to eq(1)
      expect(clients.sample.id).to eq(connected_client.id)
      expect(clients.sample.owner_email).to eq(connected_client.owner_email)
    end

    it 'should to find connected client by phone' do
      client_phone = connected_client.owner_phone_normalized
      clients = clients_query.new(advisor_with_client, { fulltext_search: client_phone }).search_clients

      expect(clients.count).to eq(1)
      expect(clients.sample.id).to eq(connected_client.id)
      expect(clients.sample.owner_phone).to eq(connected_client.owner_phone)
    end

    it 'should find unconnected client by name' do
      client_name = unconnected_client.owner_name.split(' ').last
      clients = clients_query.new(advisor_with_client, { fulltext_search: client_name }).search_clients

      expect(clients.count).to eq(1)
      expect(clients.sample.id).to eq(unconnected_client.id)
      expect(clients.sample.owner_name).to eq(unconnected_client.owner_name)
    end

    it 'should find unconnected client by email' do
      client_email = unconnected_client.owner_email
      clients = clients_query.new(advisor_with_client, { fulltext_search: client_email }).search_clients

      expect(clients.count).to eq(1)
      expect(clients.sample.id).to eq(unconnected_client.id)
      expect(clients.sample.owner_email).to eq(unconnected_client.owner_email)
    end

    it 'should find unconnected client by phone' do
      client_phone = unconnected_client.owner_phone_normalized
      clients = clients_query.new(advisor_with_client, { fulltext_search: client_phone }).search_clients

      expect(clients.count).to eq(1)
      expect(clients.sample.id).to eq(unconnected_client.id)
      expect(clients.sample.owner_phone).to eq(unconnected_client.owner_phone)
    end

    it 'should not to find client of another advisor' do
      clients = clients_query.new(advisor_with_client, { fulltext_search: client.owner_name }).search_clients

      expect(clients.count).to eq(0)
    end

    it 'should does not find any client' do
      fictitious_name = Faker::Name.name
      clients = clients_query.new(advisor_with_client, { fulltext_search: fictitious_name }).search_clients

      expect(clients.count).to eq(0)
    end

    it 'should find only connected clients for creating workflow' do
      client_name = connected_client.owner_name.split(' ').first
      clients = clients_query.new(advisor_with_client, { search_data: client_name }).search_clients

      expect(clients.count).to eq(1)
      expect(clients.sample.id).to eq(connected_client.id)
    end

    it 'should not find clients for creating workflow if client is unconnected' do
      client_name = unconnected_client.owner_name.split(' ').first
      clients = clients_query.new(advisor_with_client, { search_data: client_name }).search_clients

      expect(clients).to be_empty
    end

    it 'should not find clients for creating workflow by phone' do
      client_phone = connected_client.owner_phone
      clients = clients_query.new(advisor_with_client, { search_data: client_phone }).search_clients

      expect(clients).to be_empty
    end
  end

  context '#sort_by_unread_messages' do
    before do
      chat.chats_users_relations.create(chatable: advisor_with_client)
      chat.chats_users_relations.create(chatable: connected_client.user)
      create_list(:message, 3, :web, :with_message_users, chat: chat, sender: connected_client.user, text: Faker::Lorem.word)

      another_chat.chats_users_relations.create(chatable: advisor_with_client)
      another_chat.chats_users_relations.create(chatable: another_connected_client.user)
      create_list(:message, 2, :web, :with_message_users, chat: another_chat, sender: another_connected_client.user, text: Faker::Lorem.word)
    end

    let!(:chat)         { create(:chat) }
    let!(:another_chat) { create(:chat) }

    let!(:another_connected_client) { create(:client, :connected, advisor: advisor_with_client) }


    it 'should return list of clients ordered by count unread messages' do
      clients = clients_query.new(advisor_with_client, { sort_method: 'Unread Messages Count' }).sort_by_unread_messages

      expect(clients.first.mes_users_count).to eq(3)
      expect(clients.second.mes_users_count).to eq(2)
    end
  end

  context '#get_total_pages' do
    it 'should return total pages count if there was pagination' do
      query       = clients_query.new(advisor_with_client, { page: 2 })
      clients     = query.get_clients
      total_pages = query.get_total_pages

      expect(clients.count).to eq(7)
      expect(clients.ids).not_to include(connected_client.id)
      expect(clients.sample.advisor_id).to eq(advisor_with_client.id)

      expect(total_pages).to eq(2)
    end

    it 'should return nil if there was no pagination' do
      query       = clients_query.new(advisor_with_client, { only_connected: true })
      clients     = query.get_clients
      total_pages = query.get_total_pages

      expect(clients.count).to eq(1)
      expect(clients.ids).to include(connected_client.id)
      expect(clients.sample.advisor_id).to eq(advisor_with_client.id)

      expect(total_pages).to be_nil
    end
  end

end
