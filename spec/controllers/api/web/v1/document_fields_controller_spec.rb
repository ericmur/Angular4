require "rails_helper"
require 'spec_helper'
require 'custom_spec_helper'

describe Api::Web::V1::DocumentFieldsController do
  before do
    stub_request(:post, /.twilio.com/).to_return(status: 200)
    allow(TwilioClient).to receive_message_chain("get_instance.account.messages.create") { true }
    load_standard_documents
    load_docyt_support
  end
  
  let!(:advisor)  { create(:advisor) }
  let!(:consumer) { create(:consumer) } 
  let!(:client)   { Client.create(advisor_id: advisor.id, name: Faker::Name::first_name, consumer_id: consumer.id) }
  let!(:document) do 
    document = Document.new(FactoryGirl.attributes_for(:document))

    document.uploader = consumer
    document.document_owners << DocumentOwner.new(
      owner_id: document.uploader.id,
      owner_type: 'User'
    )

    document.document_owners << DocumentOwner.new(
      owner_id: advisor.id,
      owner_type: 'User'
    )

    document.save
    document
  end

  before do
    ConsumerAccountType.load
    StandardBaseDocument.load

    @standard_document = StandardDocument.order("RANDOM()").first

    document.update_attribute(:standard_document_id, @standard_document.id)

    @document_field_name = Faker::Lorem::sentence
    @standard_document_field_name = Faker::Lorem::sentence

    DocumentField.create!(name: @document_field_name, data_type: "string", document_id: document.id)
    DocumentField.create!(name: @standard_document_field_name, data_type: "string", standard_document_id: @standard_document.id)

    @document_field_for_document = document.document_fields.find_by(name: @document_field_name)
    @document_field_value_for_document = DocumentFieldValue.create!(
                                            input_value: Faker::Lorem::sentence, 
                                            local_standard_document_field_id: @document_field_for_document.field_id, 
                                            document_id: document.id
                                          )

    @document_field_for_standard_document = @standard_document.standard_document_fields.find_by(name: @standard_document_field_name)
    @document_field_value_for_standard_document = DocumentFieldValue.create!(
                                                    input_value: Faker::Lorem::sentence, 
                                                    local_standard_document_field_id: @document_field_for_standard_document.field_id, 
                                                    document_id: document.id
                                                  )
  end

  describe "#index" do
    context "collection" do

      it "should return list of document fields" do
        request.headers['X-USER-TOKEN'] = advisor.authentication_token
        xhr :get, :index, :client_id => client.id, :document_id => document.id
        
        document_fields = JSON.parse(response.body)['document_fields']

        expect(document_fields.count).to eq(document.document_fields.count + document.standard_document.standard_document_fields.count)
        expect(response).to have_http_status(200)
      end
    end

    context "values" do
      it "should return document field and document field value" do
        request.headers['X-USER-TOKEN'] = advisor.authentication_token
        xhr :get, :index, :client_id => client.id, :document_id => document.id
        
        document_fields = JSON.parse(response.body)['document_fields']

        document_fields.each { |field| expect(field).to include("value", "name", "id") }
        expect(response).to have_http_status(200)
      end
    end
  end
end
