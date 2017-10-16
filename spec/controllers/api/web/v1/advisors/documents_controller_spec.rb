require "rails_helper"
require 'spec_helper'
require 'custom_spec_helper'

describe Api::Web::V1::Advisors::DocumentsController do

  before do
    stub_request(:post, /.twilio.com/).to_return(status: 200)
    allow(TwilioClient).to receive_message_chain("get_instance.account.messages.create") { true }
    load_standard_documents
    load_docyt_support
  end

  let!(:advisor)  { create(:advisor) }
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

  context '#documents_via_email' do
    it 'should return list of documents for review' do
      request.headers['X-USER-TOKEN'] = advisor.authentication_token
      xhr :get, :documents_via_email

      documents_list = JSON.parse(response.body)['documents']

      expect(documents_list.count).to eq(1)
      expect(response).to have_http_status(200)
    end

    it 'should return empty with no documents via email' do
      advisor = FactoryGirl.create(:advisor)
      request.headers['X-USER-TOKEN'] = advisor.authentication_token
      xhr :get, :documents_via_email

      documents_list = JSON.parse(response.body)['documents']

      expect(documents_list).to eq([])
      expect(response).to have_http_status(200)
    end
  end

  context '#document_via_email' do
    let(:document) do
      Document.first
    end

    it 'should return single document' do
      request.headers['X-USER-TOKEN'] = advisor.authentication_token
      xhr :get, :document_via_email, id: document.id

      single_document = JSON.parse(response.body)['document']

      expect(single_document['id']).to eq(document.id)
      expect(response).to have_http_status(200)
    end

    it 'should not return array' do
      request.headers['X-USER-TOKEN'] = advisor.authentication_token
      xhr :get, :document_via_email, id: document.id

      single_document = JSON.parse(response.body)['document']

      expect(single_document).not_to be_instance_of(Array)
      expect(response).to have_http_status(200)
    end

    it 'should return nil' do
      Document.destroy_all

      request.headers['X-USER-TOKEN'] = advisor.authentication_token
      xhr :get, :document_via_email, id: 1

      single_document = JSON.parse(response.body)['document']

      expect(single_document).to eq(nil)
      expect(response).to have_http_status(404)
    end
  end
end
