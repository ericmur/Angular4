require 'rails_helper'
require 'spec_helper'
require 'custom_spec_helper'

describe Api::Categorization::V1::DocytBotCategorizationsController do
  before(:each) do
    load_standard_documents
    load_docyt_support
  end
  
  context 'update_document_type' do
    it 'should update document type' do
      user = FactoryGirl.create(:user)
      std_doc = StandardDocument.first
      doc_owner = FactoryGirl.build(:document_owner, :owner => user)
      cloud_service_folder = FactoryGirl.create(:cloud_service_path)
      document = FactoryGirl.create(:document, :cloud_service_folder_id => cloud_service_folder.id, :share_with_system => true, :consumer_id => user.id, :document_owners => [doc_owner])
      expect(document.standard_document_id).to eq(nil)
      expect(document.symmetric_keys.for_user_access(nil).first).not_to eq(nil)
      
      xhr :post, :update_document_type, document_id: document.id, predictions: { "image" => [{ "id": std_doc.id.to_s,  "score": 91.99.to_s, "name": "DRIVERS_LICENSE" }, { "id": std_doc.id.to_s,  "score": 2.99.to_s, "name": "PASSPORT" }], "keywords" => [{ "id": std_doc.id.to_s,  "score": 59.99.to_s, "name": "DRIVERS_LICENSE" }, { "id": std_doc.id.to_s,  "score": 1.99.to_s, "name": "PASSPORT" }] }
      
      expect(response).to have_http_status(200)
      document = Document.find(document.id)
      expect(document.suggested_standard_document_id).to eq(std_doc.id)
      expect(document.symmetric_keys.for_user_access(nil).first).to eq(nil)
    end

    it 'should delete document if it is from cloud scan and no suggestion is found for it' do
      user = FactoryGirl.create(:user)
      std_doc = StandardDocument.first
      doc_owner = FactoryGirl.build(:document_owner, :owner => user)
      cloud_service_folder = FactoryGirl.create(:cloud_service_path)
      document = FactoryGirl.create(:document, :cloud_service_folder_id => cloud_service_folder.id, :cloud_service_full_path => 'cloud/service/path', :share_with_system => true, :consumer_id => user.id, :document_owners => [doc_owner])
      expect(document.standard_document_id).to eq(nil)
      expect(document.symmetric_keys.for_user_access(nil).first).not_to eq(nil)
      
      xhr :post, :update_document_type, document_id: document.id, predictions: []
      
      expect(response).to have_http_status(200)
      document = Document.where(id: document.id).first
      expect(document).to eq(nil)
    end

    it 'should delete document if it is from cloud scan and no suggestion parameter is sent' do
      user = FactoryGirl.create(:user)
      std_doc = StandardDocument.first
      doc_owner = FactoryGirl.build(:document_owner, :owner => user)
      cloud_service_folder = FactoryGirl.create(:cloud_service_path)
      document = FactoryGirl.create(:document, :cloud_service_folder_id => cloud_service_folder.id, :cloud_service_full_path => 'cloud/service/path', :share_with_system => true, :consumer_id => user.id, :document_owners => [doc_owner])
      expect(document.standard_document_id).to eq(nil)
      expect(document.symmetric_keys.for_user_access(nil).first).not_to eq(nil)
      
      xhr :post, :update_document_type, document_id: document.id
      
      expect(response).to have_http_status(200)
      document = Document.where(id: document.id).first
      expect(document).to eq(nil)
    end
  end
end
