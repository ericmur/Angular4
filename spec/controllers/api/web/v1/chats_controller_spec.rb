require 'rails_helper'
require 'custom_spec_helper'

describe Api::Web::V1::ChatsController do
  before do
    load_standard_documents
    load_docyt_support
    create(:chat)
  end

  let!(:advisor)      { create(:advisor) }
  let!(:advisor_chat) { create(:chat) }

  context '#index' do
    it 'should return all chats of advisor' do
      advisor_chat.chats_users_relations.create(chatable: advisor)
      request.headers['X-USER-TOKEN'] = advisor.authentication_token

      expect_any_instance_of(Api::Web::V1::ChatsQuery).to receive(:get_all_chats).and_call_original
      xhr :get, :index

      chats = JSON.parse(response.body)['chats']

      expect(chats.size).to eq(1)
      expect(chats.sample['id']).to eq(advisor_chat.id)
    end
  end

  context '#show' do
    it 'should return chat' do
      advisor_chat.chats_users_relations.create(chatable: advisor)
      request.headers['X-USER-TOKEN'] = advisor.authentication_token

      xhr :get, :show, id: advisor_chat.id

      chat = JSON.parse(response.body)['chat']

      expect(chat['id']).to eq(advisor_chat.id)
    end

    it 'should return 404 if chat not found' do
      advisor_chat.chats_users_relations.create(chatable: advisor)
      request.headers['X-USER-TOKEN'] = advisor.authentication_token

      xhr :get, :show, id: Faker::Number.number(3)

      chat = JSON.parse(response.body)['chat']

      expect(chat).to be_nil
    end
  end
end
