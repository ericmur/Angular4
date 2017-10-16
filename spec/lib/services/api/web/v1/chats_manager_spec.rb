require 'rails_helper'
require 'spec_helper'
require 'custom_spec_helper'

RSpec.describe Api::Web::V1::ChatsManager do
  before(:each) do
    stub_request(:any, /.*twilio.com.*/).to_return(status: 200)
    allow(TwilioClient).to receive_message_chain('get_instance.account.messages.create').and_return(true)
    load_standard_documents('standard_base_documents_structure3.json')
    load_docyt_support('standard_base_documents_structure3.json')
  end

  let!(:chat_manager) { Api::Web::V1::ChatsManager }

  let!(:advisor_without_chat)  { create(:advisor) }
  let!(:consumer_without_chat) { create(:consumer) }

  context "find or create with users" do
    let!(:chat)               { create(:chat) }
    let!(:advisor_with_chat)  { create(:advisor) }
    let!(:consumer_with_chat) { create(:consumer) }

    it "should find chat if it already exists" do
      chat.chats_users_relations.create(chatable: advisor_with_chat)
      chat.chats_users_relations.create(chatable: consumer_with_chat)
      #TODO - current when we do create(:chat, :with_users) above, one chat is created for "client" (via after_create :create_chat! in client.rb) - we should not be creating a chat for client that is unconnected. Refer to DOC-1336 and DOC-1290. This test will be fixed after these tickets
      found_chat = chat_manager.new(advisor_with_chat, [consumer_with_chat])
                    .find_or_create_with_users

      expect(found_chat.id).to eq(chat.id)
      expect(found_chat.chatable_users.ids.sort).to eq([advisor_with_chat.id, consumer_with_chat.id].sort)
    end

    it "should create chat when no chat between these users exist" do
      expect {
        @created_chat = chat_manager.new(advisor_without_chat, [consumer_without_chat])
                        .find_or_create_with_users
      }.to change(Chat, :count).by(1)
      expect(@created_chat.chatable_users.ids.sort).to eq([advisor_without_chat.id, consumer_without_chat.id])
    end

    it 'should create chat for workflow' do
      allow_any_instance_of(Workflow).to receive(:create_chat_with_participants!).and_return(true)

      workflow    = create(:workflow, admin: advisor_with_chat)
      participant = create(:participant, user: consumer_with_chat, workflow: workflow)

      chat_manager.new(advisor_with_chat, [consumer_with_chat], { workflow_id: workflow.id }).find_or_create_with_users

      expect(workflow.chat).to_not be_nil
      expect(workflow.chat.chatable_users.ids.sort).to eq([advisor_with_chat.id, consumer_with_chat.id])
    end
  end

  context '#build_chat_with_users' do
    it 'should build support chat if one of the two users is support' do
      advisor_without_chat.update(standard_category_id: StandardCategory::DOCYT_SUPPORT_ID)

      chat = chat_manager.new(advisor_without_chat, [consumer_without_chat]).build_chat_with_users

      expect(chat.is_support_chat).to be_truthy
    end

    it 'should build chat with users' do
      chat = chat_manager.new(advisor_without_chat, [consumer_without_chat]).build_chat_with_users

      result_arr = chat.chats_users_relations.map { |cur| cur.chatable_id }
      expect(result_arr.sort).to eq([advisor_without_chat.id, consumer_without_chat.id])
    end
  end

end
