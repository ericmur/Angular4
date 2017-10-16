require 'rails_helper'
require 'custom_spec_helper'

describe Api::Web::V1::WorkflowsController do
  before do
    load_standard_documents
    load_docyt_support
  end

  let!(:user)     { create(:consumer) }
  let!(:advisor)  { create(:advisor) }
  let!(:category) { StandardDocument.first }
  let!(:workflow) { create(:workflow, admin: advisor) }

  context '#index' do
    it 'should return list workflows' do
      request.headers['X-USER-TOKEN'] = advisor.authentication_token
      xhr :get, :index
      workflows_list = JSON.parse(response.body)['workflows']

      expect(workflows_list.count).to eq(1)
      expect(response).to have_http_status(200)
    end

    it 'should return empty list for advisor with no clients' do
      advisor2 = FactoryGirl.create(:advisor)
      request.headers['X-USER-TOKEN'] = advisor2.authentication_token
      xhr :get, :index
      workflows_list = JSON.parse(response.body)['workflows']

      expect(workflows_list.count).to eq(0)
      expect(response).to have_http_status(200)
    end

  end

  context 'create' do
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

    before do
      request.headers['X-USER-TOKEN'] = advisor.authentication_token
    end

    it 'should create workflow with participants' do
      params = valid_workflow_params.merge(participants_without_categories)

      expect {
        xhr :post, :create, workflow: params
      }.to change(Workflow, :count).by(1)

      workflow = JSON.parse(response.body)['workflow']

      expect(workflow['name']).to eq(valid_workflow_params[:name])
      expect(workflow['purpose']).to eq(valid_workflow_params[:purpose])
      expect(workflow['participants'].count).to eq(1)

      expect(response).to have_http_status(201)
    end

    it 'should create workflow with participants and categories for workflow' do
      params = valid_workflow_params.merge(participants_without_categories.merge(standard_categories))

      expect {
        xhr :post, :create, workflow: params
      }.to change(Workflow, :count).by(1)

      workflow = JSON.parse(response.body)['workflow']
      workflow_standard_document = WorkflowStandardDocument.last

      expect(workflow_standard_document.ownerable_id).to eq(workflow['id'])
      expect(workflow_standard_document.ownerable_type).to eq(Workflow.name.to_s)

      expect(response).to have_http_status(201)
    end

    it 'should create workflow with participants and categories for every participant' do
      params = valid_workflow_params.merge(participants_with_categories)

      expect {
        xhr :post, :create, workflow: params
      }.to change(Workflow, :count).by(1)

      workflow = JSON.parse(response.body)['workflow']
      participant = workflow['participants'].sample
      workflow_standard_document = WorkflowStandardDocument.last

      expect(workflow_standard_document.ownerable_id).to eq(participant['id'])
      expect(workflow_standard_document.ownerable_type).to eq(Participant.name.to_s)

      expect(response).to have_http_status(201)
    end

    it 'should return errors when workflow params invalid' do
      expect {
        xhr :post, :create, workflow: invalid_workflow_params
      }.not_to change(Workflow, :count)

      errors = JSON.parse(response.body)

      expect(errors['name']).to include("can't be blank")
      expect(response).to have_http_status(422)
    end
  end

  context 'show' do
    before do
      request.headers['X-USER-TOKEN'] = advisor.authentication_token
    end

    it 'should return workflow of advisor' do
      xhr :get, :show, id: workflow.id

      workflow_response = JSON.parse(response.body)['workflow']

      expect(response).to have_http_status(200)
      expect(workflow_response['name']).to eq(workflow.name)
    end

    it 'should not found workflow of advisor' do
      xhr :get, :show, id: Faker::Number.number(2)

      expect(response).to have_http_status(404)
    end
  end

end
