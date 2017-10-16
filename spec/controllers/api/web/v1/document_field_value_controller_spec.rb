require "rails_helper"
require 'spec_helper'
require 'custom_spec_helper'

describe Api::Web::V1::DocumentFieldValuesController do
  before do
    load_standard_documents
    load_docyt_support
    stub_request(:post, /.twilio.com/).to_return(status: 200)
    allow(TwilioClient).to receive_message_chain("get_instance.account.messages.create") { true }

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

  let!(:new_value) { "New standard document value" }
  let!(:advisor)   { create(:advisor) }
  let!(:consumer)  { create(:consumer) }
  let!(:client)    { Client.create(advisor_id: advisor.id, name: Faker::Name::first_name, consumer_id: consumer.id) }
  let!(:document) do
    document = Document.new(FactoryGirl.attributes_for(:document))

    document.uploader = advisor
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

  let!(:another_document) do
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

  describe "#update" do
    context "standard_document_fields" do
      it "should update standard document field value" do
        request.headers['X-USER-TOKEN'] = advisor.authentication_token
        xhr :put, :update,
                  :document_id => document.id,
                  :id => @document_field_value_for_standard_document.id,
                  :document_field_value => {
                    :id => @document_field_value_for_standard_document.id,
                    input_value: new_value,
                    document_field_id: @document_field_for_standard_document.id,
                    local_standard_document_field_id: @document_field_for_standard_document.field_id
                  }

        standard_document_field_value = JSON.parse(response.body)['document_field_value']

        expect(standard_document_field_value["value"]).not_to eq(@document_field_value_for_standard_document.value)
        expect(standard_document_field_value["value"]).to eq(new_value)
        expect(standard_document_field_value["id"]).to eq(@document_field_value_for_standard_document.id)
        expect(response).to have_http_status(200)
      end
    end

    context "document_fields" do
      it "should update standard document field value" do
        request.headers['X-USER-TOKEN'] = advisor.authentication_token
        xhr :put, :update,
                  :document_id => document.id,
                  :id => @document_field_value_for_document.id,
                  :document_field_value => {
                    :id => @document_field_value_for_document.id,
                    input_value: new_value,
                    document_field_id: @document_field_for_document.id,
                    local_standard_document_field_id: @document_field_for_document.field_id
                  }

        document_field_value = JSON.parse(response.body)['document_field_value']

        expect(document_field_value["value"]).not_to eq(@document_field_value_for_document.value)
        expect(document_field_value["value"]).to eq(new_value)
        expect(document_field_value["id"]).to eq(@document_field_value_for_document.id)
        expect(response).to have_http_status(200)
      end
    end

    context 'check permition to edit' do
      it 'should return ActionController::Forbidden if document.uploader != advisor' do
        request.headers['X-USER-TOKEN'] = advisor.authentication_token
        xhr :put, :update,
                  :document_id => another_document.id,
                  :id => @document_field_value_for_document.id,
                  :document_field_value => {
                    :id => @document_field_value_for_document.id,
                    input_value: new_value,
                    document_field_id: @document_field_for_document.id,
                    local_standard_document_field_id: @document_field_for_document.field_id
                  }

        expect(response).to have_http_status(422)
      end
    end
  end

  describe "#create" do
    before(:each) do
      DocumentFieldValue.delete_all
    end

    context "standard_document_fields" do
      it "should update standard document field value" do
        request.headers['X-USER-TOKEN'] = advisor.authentication_token
        xhr :post, :create,
                  :document_id => document.id,
                  :id => @document_field_value_for_standard_document.id,
                  :document_field_value => {
                    input_value: new_value,
                    document_id: document.id,
                    document_field_id: @document_field_for_standard_document.id,
                    local_standard_document_field_id: @document_field_for_standard_document.field_id
                  }

        standard_document_field_value = JSON.parse(response.body)['document_field_value']

        expect(standard_document_field_value["value"]).to eq(new_value)
        expect(DocumentFieldValue.find_by(id: standard_document_field_value["id"])).not_to be_nil
        expect(standard_document_field_value["value"]).to eq(DocumentFieldValue.find_by(id: standard_document_field_value["id"]).value)
        expect(response).to have_http_status(200)
      end
    end

    context "document_fields" do
      it "should update standard document field value" do
        request.headers['X-USER-TOKEN'] = advisor.authentication_token
        xhr :post, :create,
                  :document_id => document.id,
                  :id => @document_field_value_for_document.id,
                  :document_field_value => {
                    input_value: new_value,
                    document_id: document.id,
                    document_field_id: @document_field_for_document.id,
                    local_standard_document_field_id: @document_field_for_document.field_id
                  }

        document_field_value = JSON.parse(response.body)['document_field_value']

        expect(document_field_value["value"]).to eq(new_value)
        expect(DocumentFieldValue.find_by(id: document_field_value["id"])).not_to be_nil
        expect(document_field_value["value"]).to eq(DocumentFieldValue.find_by(id: document_field_value["id"]).value)
        expect(response).to have_http_status(200)
      end
    end

    context 'check permition to edit' do
      it 'should return ActionController::Forbidden if document.uploader != advisor' do
        request.headers['X-USER-TOKEN'] = advisor.authentication_token
        xhr :post, :create,
                  :document_id => another_document.id,
                  :id => @document_field_value_for_document.id,
                  :document_field_value => {
                    :id => @document_field_value_for_document.id,
                    input_value: new_value,
                    document_field_id: @document_field_for_document.id,
                    local_standard_document_field_id: @document_field_for_document.field_id
                  }

        expect(response).to have_http_status(422)
      end
    end
  end
end
