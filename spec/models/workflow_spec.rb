require 'rails_helper'
require 'custom_spec_helper'

RSpec.describe Workflow, type: :model do
  before do
    stub_docyt_support_creation
  end

  context 'associations' do
    it { is_expected.to belong_to(:admin).class_name(User.name.to_s) }
    it { is_expected.to have_many(:workflow_standard_documents).dependent(:destroy) }
    it { is_expected.to have_many(:workflow_document_uploads).through(:workflow_standard_documents) }
    it { is_expected.to have_many(:messages).through(:chat) }
    it { is_expected.to have_many(:participants).dependent(:destroy) }
    it { is_expected.to have_one(:chat).dependent(:destroy) }
  end

  context 'validations' do
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_presence_of(:admin_id) }
    it { is_expected.to validate_presence_of(:end_date) }
    it { is_expected.to validate_presence_of(:status) }
    it { is_expected.to validate_inclusion_of(:status).in_array(%w(started ended)) }
  end

  context 'State machine' do
    let(:workflow) { build(:workflow) }

    it 'should contain all needed states' do
      workflow_states = Workflow.aasm.states_for_select.flatten
      expect(workflow_states).to include('started', 'ended')
    end

    it 'should be able to go to :ended state only from :started' do
      expect(workflow).to allow_event(:ending)
      expect(workflow).to allow_transition_to(:ended)
    end
  end

  context 'after_save' do
    let!(:user)     { create(:consumer) }
    let!(:advisor)  { create(:advisor) }
    let!(:workflow) { build(:workflow, admin: advisor) }

    it 'should create chat with participants and admin after save workflow' do
      workflow.participants.build(user_id: user.id)
      workflow.save

      chat_users_ids = workflow.chat.chats_users_relations.pluck(:chatable_id)

      expect(workflow.chat).to_not be_nil
      expect(chat_users_ids.count).to eq(2)
      expect(chat_users_ids.include?(user.id)).to be_truthy
      expect(chat_users_ids.include?(advisor.id)).to be_truthy
    end
  end

  context '#count_of_categories_with_documents' do
    let!(:advisor)  { create(:advisor) }
    let!(:workflow) { create(:workflow, admin: advisor) }

    let!(:workflow_standard_document_with_documents) {
      create(:workflow_standard_document, ownerable: workflow, standard_document_id: Faker::Number.number(3))
    }

    let!(:workflow_standard_document_without_documents) {
      create(:workflow_standard_document, ownerable: workflow, standard_document_id: Faker::Number.number(3))
    }

    let!(:workflow_document_upload) {
      create(:workflow_document_upload,
        user_id: Faker::Number.number(3),
        document_id: Faker::Number.number(3),
        workflow_standard_document: workflow_standard_document_with_documents,
      )
    }

    it 'should return count of workflow standard documents when they have any one uploaded documents' do
      expect(workflow.count_of_categories_with_documents).to eq(1)
    end
  end
end
