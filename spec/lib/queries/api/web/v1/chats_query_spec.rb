require 'rails_helper'
require 'custom_spec_helper'

RSpec.describe Api::Web::V1::ChatsQuery do
  before do
    load_standard_documents
    load_docyt_support
  end

  let!(:query)   { Api::Web::V1::ChatsQuery }
  let!(:advisor) { create(:advisor) }

  let!(:advisor_chat) { create(:chat) }
  let!(:another_chat) { create(:chat) }

  context '#get_all_chats' do
    it 'should return all chats where advisor is member' do
      advisor_chat.chats_users_relations.create(chatable: advisor)
      chats = query.new(advisor).get_all_chats

      expect(chats.size).to eq(1)
      expect(chats.sample.id).to eq(advisor_chat.id)
    end

    it 'should return empty relation if advisor is not a member of any chat' do
      chats = query.new(advisor).get_all_chats

      expect(chats).to be_empty
    end
  end
end
