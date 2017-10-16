require "rails_helper"
require 'spec_helper'
require 'custom_spec_helper'

RSpec.describe Api::Web::V1::DocumentFieldsQuery do
  before do
    stub_request(:post, /.twilio.com/).to_return(status: 200)
    allow(TwilioClient).to receive_message_chain("get_instance.account.messages.create") { true }
    load_standard_documents
    load_docyt_support

    @advisor = create(:advisor)
    @consumer = create(:consumer)
    @client = Client.create(advisor_id: @advisor.id, name: Faker::Name::first_name, consumer_id: @consumer.id)
    @fake_client = create(:client)
    @query = Api::Web::V1::DocumentFieldsQuery
    @document = Document.new(FactoryGirl.attributes_for(:document))
    @document.uploader = @consumer
    @document.document_owners << DocumentOwner.new(
      owner_id: @document.uploader.id,
      owner_type: 'User'
    )

    @document.document_owners << DocumentOwner.new(
      owner_id: @advisor.id,
      owner_type: 'User'
    )

    @document.save

    @standard_document = StandardDocument.order("RANDOM()").first

    @document.update_attribute(:standard_document_id, @standard_document.id)

    @document_field_name = Faker::Lorem::sentence
    @standard_document_field_name = Faker::Lorem::sentence

    DocumentField.create!(name: @document_field_name, data_type: "string", document_id: @document.id)
    DocumentField.create!(name: @standard_document_field_name, data_type: "string", standard_document_id: @standard_document.id)

    @document_field_for_document = @document.document_fields.find_by(name: @document_field_name)
    @document_field_value_for_document = DocumentFieldValue.create!(
                                            input_value: Faker::Lorem::sentence, 
                                            local_standard_document_field_id: @document_field_for_document.field_id, 
                                            document_id: @document.id
                                          )

    @document_field_for_standard_document = @standard_document.standard_document_fields.find_by(name: @standard_document_field_name)
    @document_field_value_for_standard_document = DocumentFieldValue.create!(
                                                    input_value: Faker::Lorem::sentence, 
                                                    local_standard_document_field_id: @document_field_for_standard_document.field_id, 
                                                    document_id: @document.id
                                                  )
  end

  describe "get document fields" do
    context "params" do
      context "should return empty collection" do
        it "fake client, blank document_id" do
          document_fields_query = @query.new(@advisor, { client_id: @fake_client.id })
          result = document_fields_query.get_document_fields
          expect(result).to be_empty
        end

        it "fake client, fake document_id" do
          document_fields_query = @query.new(@advisor, { client_id: @fake_client.id, document_id: 0 })
          result = document_fields_query.get_document_fields
          expect(result).to be_empty
        end

        it "fake client, present document_id with permission" do
          document_fields_query = @query.new(@advisor, { client_id: @fake_client.id, document_id: @document.id })
          result = document_fields_query.get_document_fields
          expect(result).not_to be_empty
        end

        it "fake document_id, blank client" do
          document_fields_query = @query.new(@advisor, { document_id: 0 })
          result = document_fields_query.get_document_fields
          expect(result).to be_empty
        end

        it "fake document_id, present client" do
          document_fields_query = @query.new(@advisor, { document_id: 0, client_id: @client.id })
          result = document_fields_query.get_document_fields
          expect(result).to be_empty
        end

        it "blank client, blank document_id" do
          document_fields_query = @query.new(@advisor, {})
          result = document_fields_query.get_document_fields
          expect(result).to be_empty
        end

        it "present client, present document_id should show only default standard_document_fields" do
          @document_field_for_document.destroy
          @document_field_value_for_document.destroy
          @document_field_for_standard_document.destroy
          @document_field_value_for_standard_document.destroy

          standard_document = StandardDocument.find_by(id: @document.standard_document_id)
          standard_document_fields = standard_document.standard_document_fields

          document_fields_query = @query.new(@advisor, {document_id: @document.id, client_id: @client.id})
          result = document_fields_query.get_document_fields
          expect(result.collect { |record| record.id }).to eq(standard_document_fields.ids)
        end
      end

      context "should not return empty collection" do
        it "present client, present document" do
          document_fields_query = @query.new(@advisor, {document_id: @document.id, client_id: @client.id})
          result = document_fields_query.get_document_fields
          expect(result).not_to be_empty
        end
      end
    end

    context "result" do
      it "should return correct values" do
        document_fields_query = @query.new(@advisor, {document_id: @document.id, client_id: @client.id})
        result = document_fields_query.get_document_fields
        field1 = result.find { |field| field.name == @document_field_name }
        field2 = result.find { |field| field.name == @standard_document_field_name }

        expect(field1.id).to eq(@document_field_for_document.id)
        expect(field1.id).not_to be_nil
        expect(field1.name).to eq(@document_field_for_document.name)
        expect(field1.name).not_to be_nil
        expect(field1.value).to eq(@document_field_value_for_document.value)
        expect(field1.value).not_to be_nil

        expect(field2.id).to eq(@document_field_for_standard_document.id)
        expect(field2.id).not_to be_nil
        expect(field2.name).to eq(@document_field_for_standard_document.name)
        expect(field2.name).not_to be_nil
        expect(field2.value).to eq(@document_field_value_for_standard_document.value)
        expect(field2.value).not_to be_nil
      end
    end

    context "type" do
      it "should return Array type" do
        document_fields_query = @query.new(@advisor, {document_id: @document.id, client_id: @client.id})
        result = document_fields_query.get_document_fields
        expect(result).to be_kind_of(Array)
      end
    end
  end
end
