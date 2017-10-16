require "rails_helper"
require 'spec_helper'
require 'custom_spec_helper'

describe Api::Web::V1::StandardDocumentsController do

  before(:each) do
    load_standard_documents
    load_docyt_support
  end

  let!(:advisor)      { create(:advisor) }
  let!(:client)       { create(:client, advisor: advisor) }
  let!(:fake_client)  { create(:client) }

  let!(:advisor_support) { User.find_by(email: "support@docyt.com") }

  context "#index" do
    it 'should return list of standards' do
      request.headers['X-USER-TOKEN'] = advisor.authentication_token
      expect(Api::Web::V1::StandardDocumentsQuery).to receive(:new).with(any_args).and_call_original
      expect_any_instance_of(Api::Web::V1::StandardDocumentsQuery).to receive(:get_document_types).and_call_original

      xhr :get, :index, client_id: client.id, client_type: 'Client'

      standards = JSON.parse(response.body)['standard_documents']

      expect(standards.count).to eq(StandardDocument.count)
      expect(response).to have_http_status(200)
    end

    it 'should return list standard document for advisor if no client' do
      request.headers['X-USER-TOKEN'] = advisor.authentication_token
      expect(Api::Web::V1::StandardDocumentsQuery).to receive(:new).with(any_args).and_call_original
      expect_any_instance_of(Api::Web::V1::StandardDocumentsQuery).to receive(:get_document_types).and_call_original

      xhr :get, :index, client_id: fake_client.id

      standards = JSON.parse(response.body)['standard_documents']

      expect(standards.count).to eq(StandardDocument.count)
      expect(response).to have_http_status(200)

      categories = JSON.parse(response.body)['standard_documents']
      expect(categories).to_not be_empty
    end

    it "should return client-created standard" do
      standard_document = create(:standard_document, :with_client_owner, :consumer_id => advisor.id)
      advisor.clients_as_advisor << standard_document.owners.first.owner
      request.headers['X-USER-TOKEN'] = advisor.authentication_token
      expect(Api::Web::V1::StandardDocumentsQuery).to receive(:new).with(any_args).and_call_original
      expect_any_instance_of(Api::Web::V1::StandardDocumentsQuery).to receive(:get_document_types).and_call_original

      xhr :get, :index, :client_id => standard_document.owners.first.owner.id, :client_type => 'Client'

      standards = JSON.parse(response.body)['standard_documents']

      has_id = standards.inject(false) { |res, e| res || (e['id'] == standard_document.id) }

      expect(has_id).to be true
    end

    it "each client should access just own standards" do
      standard_document = create(:standard_document, :with_client_owner, :consumer_id => advisor.id)
      client = standard_document.owners.first.owner
      advisor.clients_as_advisor << client
      request.headers['X-USER-TOKEN'] = advisor.authentication_token
      expect(Api::Web::V1::StandardDocumentsQuery).to receive(:new).with(any_args).and_call_original
      expect_any_instance_of(Api::Web::V1::StandardDocumentsQuery).to receive(:get_document_types).and_call_original
      xhr :get, :index, :client_id => client.id, :client_type => 'Client'

      standards = JSON.parse(response.body)['standard_documents']

      expect(standards.map{ |s| s["id"] }).to include(standard_document.id)
      expect(standards.reject { |s| s["id"] == standard_document.id }.find { |s| StandardDocument.find(s["id"]).owners.first }).to be_nil
    end

    it 'should return all standard documents for advisor support' do
      standard_document = create(:standard_document, :with_client_owner, consumer_id: advisor.id)

      request.headers['X-USER-TOKEN'] = advisor_support.authentication_token
      xhr :get, :index, client_id: advisor_support.id, for_support: true, per_page: 100
      expect(response).to have_http_status(200)

      categories = JSON.parse(response.body)['standard_documents']
      meta_data  = JSON.parse(response.body)['meta']

      expect(categories.count).to eq(StandardDocument.count)
      expect(meta_data['pages_count']).to eq(1)
    end

    it 'should return standard documents of uploaded client documents for advisor support' do
      connected_client  = create(:client, :connected, advisor: advisor)
      document = create(:document, :with_owner, uploader: connected_client.user, standard_document: StandardDocument.first)

      request.headers['X-USER-TOKEN'] = advisor_support.authentication_token
      xhr :get, :index, client_id: advisor_support.id, for_client_id: connected_client.id, for_support: true
      expect(response).to have_http_status(200)

      categories = JSON.parse(response.body)['standard_documents']
      meta_data  = JSON.parse(response.body)['meta']

      expect(categories.count).to eq(1)
      expect(categories.first['client_uploaded_documents_count']).to eq(1)
    end
  end

  context '#show' do
    let!(:standard_document) { create(:standard_document, :with_client_owner, consumer_id: advisor.id) }

    before do
      request.headers['X-USER-TOKEN'] = advisor.authentication_token
    end

    it 'should return standard document if it exists' do
      xhr :get, :show, :client_id => advisor.id, id: standard_document.id
      expect(response).to have_http_status(200)

      category = JSON.parse(response.body)['standard_document']
      expect(category['id']).to eq(standard_document.id)
    end

    it 'should return 404 if standard document is not exists' do
      xhr :get, :show, :client_id => advisor.id, id: Faker::Number.number(3)
      expect(response).to have_http_status(404)

      category = JSON.parse(response.body)['standard_document']
      expect(category).to be_nil
    end
  end
end
