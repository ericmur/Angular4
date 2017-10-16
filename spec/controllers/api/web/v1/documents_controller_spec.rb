require 'rails_helper'
require 'custom_spec_helper'

describe Api::Web::V1::DocumentsController do
  before do
    stub_request(:post, /.twilio.com/).to_return(status: 200)
    allow(TwilioClient).to receive_message_chain("get_instance.account.messages.create") { true }
    load_standard_documents
    load_docyt_support
  end

  let(:documents_query) { Api::Web::V1::DocumentsQuery }

  let(:client)   { create(:client, advisor: advisor, consumer: consumer) }
  let(:advisor)  { create(:advisor) }
  let(:business) { create(:business) }
  let(:consumer) { document_with_owner.uploader }

  let(:documents_query)      { Api::Web::V1::DocumentsQuery }
  let!(:document_with_owner) { create(:document, :with_uploader_and_owner) }

  context '#show' do
    it 'should return a document and symmetric_key shared with this client' do
      request.headers['X-USER-TOKEN'] = advisor.authentication_token
      Rails.stub(:app_type) { User::MOBILE_APP }
      Rails.stub(:user_password_hash) { consumer.password_hash("123456") }
      document_with_owner.share_with(:by_user_id => consumer.id, :with_user_id => advisor.id)
      Rails.stub(:app_type) { User::WEB_APP }
      Rails.stub(:user_password_hash) { advisor.password_hash("test_password") }
      xhr :get, :show, :client_id => client.id, :id => document_with_owner.id

      document = JSON.parse(response.body)['document']

      expect(document['id']).to eq(document_with_owner.id)
      expect(document['final_file_key']).to eq(document_with_owner.final_file_key)
      expect(document['symmetric_key']['created_for_user_id']).to eq(advisor.id)
      expect(response).to have_http_status(200)
    end

    it 'should return status 404 if there is no document found' do
      advisor = FactoryGirl.create(:advisor)
      client  = FactoryGirl.create(:client, :advisor => advisor)
      request.headers['X-USER-TOKEN'] = advisor.authentication_token

      xhr :get, :show, :client_id => client.id, :id => document_with_owner.id

      expect(response).to have_http_status(404)
    end
  end

  context '#index' do
    it 'should return list of documents from get_documents' do
      request.headers['X-USER-TOKEN'] = advisor.authentication_token
      Rails.stub(:app_type) { User::MOBILE_APP }
      Rails.stub(:user_password_hash) { consumer.password_hash("123456") }
      document_with_owner.share_with(:by_user_id => consumer.id, :with_user_id => advisor.id)
      allow_any_instance_of(documents_query).to receive(:get_documents).and_return(Document.all)
      expect_any_instance_of(documents_query).to receive(:get_documents)
      xhr :get, :index, :client_id => client.id

      documents_list = JSON.parse(response.body)['documents']

      expect(documents_list).not_to be_empty
      expect(response).to have_http_status(200)
    end

    it 'should return list of documents from get_documents_for_contact' do
      request.headers['X-USER-TOKEN'] = advisor.authentication_token
      Rails.stub(:app_type) { User::MOBILE_APP }
      Rails.stub(:user_password_hash) { consumer.password_hash("123456") }
      document_with_owner.share_with(:by_user_id => consumer.id, :with_user_id => advisor.id)
      allow_any_instance_of(documents_query).to receive(:get_documents_for_contact).and_return(Document.all)
      expect_any_instance_of(documents_query).to receive(:get_documents_for_contact)
      xhr :get, :index, :client_id => client.id, :structure_type => 'flat'

      documents_list = JSON.parse(response.body)['documents']

      expect(documents_list).not_to be_empty
      expect(response).to have_http_status(200)
    end

    it 'should return list of shared documents with this client' do
      request.headers['X-USER-TOKEN'] = advisor.authentication_token
      Rails.stub(:app_type) { User::MOBILE_APP }
      Rails.stub(:user_password_hash) { consumer.password_hash("123456") }
      document_with_owner.share_with(:by_user_id => consumer.id, :with_user_id => advisor.id)
      xhr :get, :index, :client_id => client.id

      documents_list = JSON.parse(response.body)['documents']

      expect(documents_list.count).to eq(consumer.uploaded_documents.count)
      expect(response).to have_http_status(200)
    end

    it 'should return empty list for a client with no documents' do
      advisor = FactoryGirl.create(:advisor)
      client = FactoryGirl.create(:client, :advisor => advisor)
      request.headers['X-USER-TOKEN'] = advisor.authentication_token

      xhr :get, :index, :client_id => client.id

      documents_list = JSON.parse(response.body)['documents']

      expect(documents_list).to eq([])
      expect(response).to have_http_status(200)
    end

    it 'should return categorized documents for advisor support' do
      document = create(:document, :with_standard_document)
      allow_any_instance_of(User).to receive(:docyt_support?).and_return(true)

      request.headers['X-USER-TOKEN'] = advisor.authentication_token
      xhr :get, :index, only_categorized: true, for_support: true

      documents_list = JSON.parse(response.body)['documents']

      expect(documents_list.size).to eq(1)
      expect(documents_list.sample['id']).to eq(document.id)
    end

    it 'should not return documents if advisor is not support' do
      document = create(:document, :with_standard_document)

      request.headers['X-USER-TOKEN'] = advisor.authentication_token
      xhr :get, :index, only_categorized: true, for_support: true

      documents_list = JSON.parse(response.body)['documents']

      expect(documents_list).to be_empty
    end

    it 'should return not categorized documents for business' do
      document = create(:document, uploader: advisor)
      business = create(:business)

      create(:business_partner, user: advisor, business: business)
      create(:business_document, document: document, business: business)

      request.headers['X-USER-TOKEN'] = advisor.authentication_token
      xhr :get, :index, business_id: business.id

      documents_list = JSON.parse(response.body)['documents']

      expect(documents_list.size).to eq(1)
      expect(documents_list.sample['id']).to eq(document.id)
    end
  end

  context '#create' do
    before do
      request.headers['X-USER-TOKEN'] = advisor.authentication_token
    end

    let(:valid_create_params) {
      {
        "client_id" => client.id,
        "storage_size"=> Faker::Number.number(4).to_s,
        "file_content_type"=> "image/png",
        "original_file_name" => "#{Faker::Lorem.word}.png",
        "document_owners"=> [{ "owner_type"=>"Consumer", "owner_id"=> client.consumer_id },
                             { "owner_type"=>"Advisor",  "owner_id"=> advisor.id }]
      }
    }

    let(:valid_create_params_with_client_uploader) {
      {
        "client_id" => client.id,
        "storage_size"=> Faker::Number.number(4).to_s,
        "file_content_type"=> "image/png",
        "original_file_name" => "#{Faker::Lorem.word}.png",
        "document_owners"=> [{ "owner_type"=>"Client",  "owner_id"=> client.id },
                             { "owner_type"=>"Advisor", "owner_id"=> advisor.id }]
      }
    }

    let(:valid_create_params_for_chat_document) {
      {
        "temporary" => true,
        "storage_size"=> Faker::Number.number(4).to_s,
        "file_content_type"=> "image/png",
        "original_file_name" => "#{Faker::Lorem.word}.png",
        "chat_members" => [{ "type" => client.consumer.class.name.to_s, "id" => client.consumer.id }]
      }
    }

    let(:valid_create_params_for_business_document) {
      {
        "business_id" => business.id,
        "storage_size"=> Faker::Number.number(4).to_s,
        "file_content_type"=> "image/png",
        "original_file_name" => "#{Faker::Lorem.word}.png",
      }
    }

    let(:invalid_create_params) {
      {
        "client_id" => client.id,
        "storage_size"=> Faker::Number.number(4).to_s,
        "file_content_type"=> "image/png",
        "original_file_name" => "#{Faker::Lorem.word}.png",
        "document_owners"=> [{ "owner_type"=> "root", "owner_id"=> advisor.id }]
      }
    }

    it 'should create and return document when params valid' do
      expect { xhr :post, :create, document: valid_create_params }.to change(Document, :count).by(1)

      document = JSON.parse(response.body)['document']

      expect(document['original_file_name']).to eq(valid_create_params['original_file_name'])
      expect(document['storage_size'].to_s).to eq(valid_create_params['storage_size'])
      expect(document['file_content_type']).to eq(valid_create_params['file_content_type'])

      expect(response).to have_http_status(201)
    end

    it 'should create and return document when uploaded for client' do
      expect { xhr :post, :create, document: valid_create_params_with_client_uploader }.to change(Document, :count).by(1)

      expect(response).to have_http_status(201)
    end

    it 'should share document with client when it was a temporary document sent to client via chat' do
      expect { xhr :post, :create, document: valid_create_params_for_chat_document }.to change(Document, :count).by(1)

      doc = Document.order("id DESC").first
      expect(doc.symmetric_keys.count).to eq(2)
      expect(doc.symmetric_keys.map(&:created_for_user_id)).to include(client.consumer_id)
      expect(response).to have_http_status(201)
    end

    it 'should not assign owners to a document when it was a temporary document sent to client via chat' do
      expect { xhr :post, :create, document: valid_create_params_for_chat_document }.to change(Document, :count).by(1)

      doc = Document.order("id DESC").first
      expect(doc.document_owners.count).to eq(0)
      expect(doc.symmetric_keys.map(&:created_for_user_id)).to include(client.consumer_id)
      expect(response).to have_http_status(201)
    end

    it 'should create business document' do
      create(:business_partner, user: advisor, business: business)

      expect { xhr :post, :create, document: valid_create_params_for_business_document }.to change(Document, :count).by(1)

      document = JSON.parse(response.body)['document']

      expect(document['standard_document']).to be_nil
      expect(business.business_documents.pluck(:document_id)).to include(document['id'])
    end

    it 'should not create and return document when params invalid', focus: true do
      expect { xhr :post, :create, document: invalid_create_params }.not_to change(Document, :count)

      errors = JSON.parse(response.body)

      expect(errors).to eq({"base"=>["No document owner provided when uploading the document"]})
      expect(response).to have_http_status(422)
    end
  end

  context '#destroy' do
    it 'should successfuly destroy document when params valid' do
      request.headers['X-USER-TOKEN'] = advisor.authentication_token
      Rails.stub(:app_type) { User::MOBILE_APP }
      Rails.stub(:user_password_hash) { consumer.password_hash("123456") }
      document_with_owner.share_with(:by_user_id => consumer.id, :with_user_id => advisor.id)

      expect {
        xhr :delete, :destroy, { :client_id => client.id, :id => document_with_owner.id }
      }.to change(Document, :count).by(-1)

      expect(response).to have_http_status(204)
    end

    it 'should not destroy document when params invalid' do
      request.headers['X-USER-TOKEN'] = advisor.authentication_token

      expect {
        xhr :delete, :destroy, { :client_id => client.id, :id => document_with_owner.id }
      }.not_to change(Document, :count)

      expect(response).to have_http_status(404)
    end
  end

  context '#complete_upload' do
    let(:s3_object_key) { "#{Faker::Lorem.word}.jpg" }

    let(:valid_upload_params) {
      {
        "final_file_key" => s3_object_key,
        "s3_object_key" => s3_object_key
      }
    }
    let(:invalid_upload_params) {
      {
        "final_file_key" => "",
        "s3_object_key" => ""
      }
    }

    it 'should update document path on s3 and return document with updated status when params valid' do
      request.headers['X-USER-TOKEN'] = advisor.authentication_token
      Rails.stub(:user_password_hash) { consumer.password_hash("123456") }
      Rails.stub(:app_type) { User::MOBILE_APP }

      document_with_owner.share_with(by_user_id: consumer.id, with_user_id: advisor.id)
      allow_any_instance_of(Document).to receive(:s3_object_exists?).and_return(true)

      expect_any_instance_of(Document).to receive(:complete_upload).and_call_original
      expect_any_instance_of(Document).to receive(:start_convertation!).and_call_original
      Rails.stub(:user_password_hash) { advisor.password_hash('test_password') }
      Rails.stub(:app_type) { User::WEB_APP }

      xhr :put, :complete_upload, id: document_with_owner.id, document: valid_upload_params.merge(client_id: client.id,
        id: document_with_owner.id)

      document = JSON.parse(response.body)['document']
      expect(document['state']).to eq("converting")
      expect(document['original_file_key']).to eq(valid_upload_params["final_file_key"])
      expect(response).to have_http_status(200)
    end

    it 'should not create and return document when params invalid', focus: true do
      request.headers['X-USER-TOKEN'] = advisor.authentication_token
      Rails.stub(:user_password_hash) {  consumer.password_hash("123456") }
      Rails.stub(:app_type) { User::MOBILE_APP }
      document_with_owner.share_with(by_user_id: consumer.id, with_user_id: advisor.id)
      Rails.stub(:user_password_hash) { advisor.password_hash('test_password') }
      Rails.stub(:app_type) { User::WEB_APP }

      xhr :put, :complete_upload, id: document_with_owner.id, document: invalid_upload_params.merge(client_id: client.id,
        id: document_with_owner.id)

      expect_any_instance_of(Document).not_to receive(:complete_upload)
      expect_any_instance_of(Document).not_to receive(:start_convertation)

      errors = JSON.parse(response.body)

      expect(errors).to eq({"original_file_key"=>["S3 file path is not set"]})
      expect(response).to have_http_status(422)
    end
  end

  context '#assign' do
    let!(:email_attached_document) do
      attributes = attributes_for(:document, :attached_to_email)
      attributes[:uploader] = advisor
      attributes[:email] = create(:email)
      attributes[:source] = 'ForwardedEmail'
      doc = Document.new(attributes)
      doc.document_owners << DocumentOwner.new(owner_id: doc.uploader.id, owner_type: 'User')
      doc.save
      doc
    end

    let(:assignment_params) {
      {
        :ids => [email_attached_document.id]
      }
    }

    let(:invalid_document_assignment_params) {
      {
        :ids => [document_with_owner.id]
      }
    }

    it 'should return list of assigned documents' do
      request.headers['X-USER-TOKEN'] = advisor.authentication_token

      expect {
        xhr :get, :assign, :client_id => client.id, :shared_documents => assignment_params
      }.to change(DocumentOwner, :count).by(1)

      documents_list = JSON.parse(response.body)['documents']

      expect(documents_list.count).to eq(1)
      expect(response).to have_http_status(200)
    end

    it 'should return error with wrong client' do
      client = FactoryGirl.create(:client)
      request.headers['X-USER-TOKEN'] = advisor.authentication_token

      expect {
        xhr :get, :assign, :client_id => client.id, :shared_documents => assignment_params
      }.not_to change(DocumentOwner, :count)

      expect(response.body).to include('Error')
      expect(response).to have_http_status(422)
    end

    it 'should return empty array for wrong document' do
      request.headers['X-USER-TOKEN'] = advisor.authentication_token

      expect {
        xhr :get, :assign, :client_id => client.id, :shared_documents => invalid_document_assignment_params
      }.not_to change(DocumentOwner, :count)

      documents_list = JSON.parse(response.body)['documents']

      expect(documents_list).to eq([])
      expect(response).to have_http_status(200)
    end
  end

  context '#search' do
    it 'should return list of documents found' do
      request.headers['X-USER-TOKEN'] = advisor.authentication_token
      Rails.stub(:user_password_hash) { consumer.password_hash("123456") }
      allow_any_instance_of(documents_query).to receive(:search_documents).and_return(Document.all)
      expect_any_instance_of(documents_query).to receive(:search_documents)
      xhr :get, :search, :client_id => client.id

      documents_list = JSON.parse(response.body)['documents']

      expect(documents_list).not_to be_empty
      expect(response).to have_http_status(200)
    end
  end
end
