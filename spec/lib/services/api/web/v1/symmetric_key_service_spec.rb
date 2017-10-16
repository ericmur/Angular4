require 'rails_helper'
require 'custom_spec_helper'

RSpec.describe Api::Web::V1::SymmetricKeyService do
  before do
    Rails.set_app_type(User::WEB_APP)
    load_standard_documents
    load_docyt_support
  end

  let!(:service)  { Api::Web::V1::SymmetricKeyService }
  let!(:advisor)  { create(:advisor) }
  let!(:document) { create(:document, uploader: advisor, source: 'WebChat') }

  let!(:connected_client) { create(:client, :connected) }
  let!(:another_connected_client) { create(:client, :connected) }

  let!(:chat_members) {
    [
      { 'id' => connected_client.consumer.id, 'type' => connected_client.consumer.class.name.to_s },
      { 'id' => another_connected_client.consumer.id, 'type' => another_connected_client.consumer.class.name.to_s }
    ]
  }
  let!(:document_owners_params) { [{ "owner_type" => GroupUser.name.to_s }] }

  context '#create_keys' do
    it 'should create symmetric key for client' do
      expect {
        service.new(advisor,
          { client_id: connected_client.id, document: document, document_owners_params: document_owners_params }
        ).create_keys
      }.to change{ SymmetricKey.count }.by(1)
    end

    it 'should create symmetric keys for chat members' do
      expect {
        service.new(advisor,
          { chat_members: chat_members, document: document, temporary: true }
        ).create_keys
      }.to change{ SymmetricKey.count }.by(2)
    end

    it 'should not create symmetric key' do
      expect { service.new(advisor, {}).create_keys }.not_to change{ SymmetricKey.count }
    end
  end
end
