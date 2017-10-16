require "rails_helper"
require 'spec_helper'
require 'custom_spec_helper'

RSpec.describe Api::Web::V1::DocumentFieldValueCreateForm do
  before do
    load_standard_documents
    load_docyt_support
    stub_request(:post, /.twilio.com/).to_return(status: 200)
    allow(TwilioClient).to receive_message_chain("get_instance.account.messages.create") { true }

    DocumentField.create!(name: document_field_name, data_type: "string", document_id: document.id)
  end

  let!(:form)      { Api::Web::V1::DocumentFieldValueCreateForm }
  let!(:advisor)   { create(:advisor) }
  let!(:new_value) { Faker::Lorem::sentence }

  let!(:document_field_name) { Faker::Lorem::sentence }
  let!(:document_field_for_document) { document.document_fields.find_by(name: document_field_name) }

  let!(:document) do
    document = Document.new(FactoryGirl.attributes_for(:document))

    document.uploader = advisor
    document.document_owners << DocumentOwner.new(
      owner_id: document.uploader.id,
      owner_type: 'User'
    )

    document.save
    document
  end

  let!(:valid_document_field_value_params) {
    {
      input_value: new_value,
      document_id: document.id,
      document_field_id: document_field_for_document.id,
      local_standard_document_field_id: document_field_for_document.field_id
    }
  }

  let!(:invalid_document_field_value_params) {
    {
      input_value: '',
      document_id: '',
      document_field_id: document_field_for_document.id,
      local_standard_document_field_id: document_field_for_document.field_id
    }
  }

  context '#save' do
    it 'should create document field value' do
      doc_field_value = form.from_params(valid_document_field_value_params, user_id: advisor.id)

      expect{ doc_field_value.save }.to change{ DocumentFieldValue.count }.from(0).to(1)
      expect(DocumentFieldValue.first.value).to eq(new_value)
    end

    it 'should not create document field value' do
      doc_field_value = form.from_params(invalid_document_field_value_params, user_id: advisor.id)

      expect{ doc_field_value.save }.not_to change{ DocumentFieldValue.count }
    end
  end
end
