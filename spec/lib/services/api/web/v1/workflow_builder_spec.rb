require 'rails_helper'
require 'custom_spec_helper'

RSpec.describe Api::Web::V1::WorkflowBuilder do
  before do
    load_standard_documents
    load_docyt_support
  end

  let!(:service) { Api::Web::V1::WorkflowBuilder }

  let!(:user)    { create(:consumer) }
  let!(:advisor) { create(:advisor) }

  let!(:category) { StandardDocument.first }

  let!(:valid_workflow_params) {
    {
      :name => Faker::Name.title,
      :purpose => Faker::Name.title,
      :end_date => Date.current
    }
  }

  let!(:invalid_workflow_params) {
    {
      :name => '',
      :purpose => '',
      :end_date => ''
    }
  }

  let!(:participants_with_categories) {
    {
      :same_documents_for_all => false,
      :participants => [
        {
          :consumer_id => user.id,
          :standard_documents => [{ :category_id => category.id }]
        }
      ]
    }
  }

  let!(:participants_without_categories) {
    {
      :same_documents_for_all => true,
      :participants => [{ :consumer_id => user.id }]
    }
  }

  let!(:standard_categories) {
    {
      :standard_documents => [{ :category_id => category.id }]
    }
  }

  context '#create_workflow' do
    it 'should create workflow with participants' do
      params = valid_workflow_params.merge(participants_without_categories)

      expect {
        service.new(advisor, params).create_workflow
      }.to change{ Workflow.count }

      workflow = Workflow.last
      expect(workflow.name).to eq(params[:name])
      expect(workflow.purpose).to eq(params[:purpose])
      expect(workflow.end_date).to eq(params[:end_date])

      expect(workflow.participants.count).to eq(1)
    end

    it 'should create workflow with participants and categories for workflow' do
      params = valid_workflow_params.merge(participants_without_categories.merge(standard_categories))

      expect {
        service.new(advisor, params).create_workflow
      }.to change{ Workflow.count }

      workflow = Workflow.last
      workflow_category = workflow.workflow_standard_documents.sample

      expect(workflow_category.standard_document_id).to eq(category.id)
      expect(workflow_category.ownerable_id).to eq(workflow.id)
      expect(workflow_category.ownerable_type).to eq(workflow.class.name.to_s)

      expect(workflow.workflow_standard_documents.count).to eq(1)
    end

    it 'should create workflow with participants and categories for every participant' do
      params = valid_workflow_params.merge(participants_with_categories)

      expect {
        service.new(advisor, params).create_workflow
      }.to change{ Workflow.count }

      workflow = Workflow.last
      participant = workflow.participants.last
      participant_category = participant.workflow_standard_documents.sample

      expect(participant_category.standard_document_id).to eq(category.id)
      expect(participant_category.ownerable_id).to eq(participant.id)
      expect(participant_category.ownerable_type).to eq(Participant.name.to_s)

      expect(participant.workflow_standard_documents.count).to eq(1)
    end

    it 'should not create workflow' do
      expect {
        service.new(advisor, invalid_workflow_params).create_workflow
      }.not_to change{ Workflow.count }
    end
  end

end
