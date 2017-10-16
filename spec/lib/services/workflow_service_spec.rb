require 'rails_helper'
require 'custom_spec_helper'

RSpec.describe WorkflowService do
  before do
    Rails.set_app_type(User::WEB_APP)
    load_standard_documents
    load_docyt_support
  end

  let!(:service)  { WorkflowService }

  let!(:user)  { create(:consumer) }
  let!(:admin) { create(:advisor) }

  let!(:workflow) { create(:workflow, admin: admin) }

  let!(:standard_document) { StandardDocument.first }

  context '#create_workflow' do
    it 'should create workflow with realy user' do
      expect{
        service.new(
          {
            name: Faker::Commerce.product_name,
            user_id: admin.id,
            end_date: Faker::Date.forward(10)
          }
        ).create_workflow
      }.to change{ Workflow.count }.by(1)
    end

    it 'should not create workflow if nonexistent user' do
      expect{
        service.new(
          {
            name: Faker::Commerce.product_name,
            user_id: Faker::Number.number(3),
            end_date: Faker::Date.forward(10)
          }
        ).create_workflow
      }.not_to change{ Workflow.count }
    end
  end

  context '#add_participant' do
    it 'should find user and create participant for workflow' do
      expect{
        service.new(
          {
            user_id: user.id,
            workflow_id: workflow.id
          }
        ).add_participant
      }.to change{ workflow.participants.count }
    end

    it 'should not create participant for workflow with nonexistent user' do
      expect{
        service.new(
          {
            user_id: Faker::Number.number(3),
            workflow_id: workflow.id
          }
        ).add_participant
      }.not_to change{ workflow.participants.count }

    end

    it 'should not create participant for nonexistent workflow' do
      expect{
        service.new(
          {
            user_id: user.id,
            workflow_id: Faker::Number.number(3)
          }
        ).add_participant
      }.not_to change{ workflow.participants.count }
    end
  end

  context '#add_standard_document' do
    it 'find and add standard document for workflow' do
      expect{
        service.new(
          {
            workflow_id: workflow.id,
            standard_document_id: standard_document.id
          }
        ).add_standard_document
      }.to change{ workflow.workflow_standard_documents.count }
    end

    it 'should not create for workflow standard document if it is non-existent' do
      expect{
        service.new(
          {
            workflow_id: workflow.id,
            standard_document_id: Faker::Number.number(3)
          }
        ).add_standard_document
      }.not_to change{ workflow.workflow_standard_documents.count }
    end

    it 'should not create standard document for nonexistent workflow' do
      expect{
        service.new(
          {
            workflow_id: Faker::Number.number(3),
            standard_document_id: standard_document.id
          }
        ).add_standard_document
      }.not_to change{ workflow.workflow_standard_documents.count }
    end
  end

  context '#require_participant_to_upload' do
    before do
      @participant = workflow.participants.create(user: user)
    end

    it 'should update require upload standard document for participant' do
      service.new(
        {
          user_id: user.id,
          workflow_id: workflow.id,
          standard_document_id: standard_document.id
        }
      ).require_participant_to_upload

      @participant.reload

      expect(@participant.workflow_standard_documents.first.standard_document_id).to eq(standard_document.id)
    end

    it 'should not update require upload standard document for nonexistent workflow' do
      service.new(
        {
          user_id: user.id,
          workflow_id: Faker::Number.number(3),
          standard_document_id: standard_document.id
        }
      ).require_participant_to_upload

      @participant.reload

      expect(@participant.workflow_standard_documents.blank?).to be_truthy
    end

    it 'should not update require upload for participant if it is not associated with workflow' do
      @participant.update(workflow_id: Faker::Number.number(3))

      service.new(
        {
          user_id: user.id,
          workflow_id: workflow.id,
          standard_document_id: standard_document.id
        }
      ).require_participant_to_upload

      @participant.reload

      expect(@participant.workflow_standard_documents.blank?).to be_truthy
    end

    it 'should not update require upload with nonexistent standard document' do
      service.new(
        {
          user_id: user.id,
          workflow_id: workflow.id,
          standard_document_id: Faker::Number.number(3)
        }
      ).require_participant_to_upload

      @participant.reload

      expect(@participant.workflow_standard_documents.blank?).to be_truthy
    end
  end
end
