require "rails_helper"
require 'custom_spec_helper'

RSpec.describe Api::Web::V1::StandardDocumentsQuery do
  before do
    load_standard_documents
    load_docyt_support
  end

  let!(:query)        { Api::Web::V1::StandardDocumentsQuery }
  let!(:client)       { Client.create(advisor_id: advisor.id, name: Faker::Name::first_name) }
  let!(:advisor)      { create(:advisor, :standard_category => StandardCategory.first) }
  let!(:fake_client)  { create(:client) }

  let!(:advisor_support)  { User.find_by(email: "support@docyt.com") }
  let!(:connected_client) { create(:client, :connected, advisor: advisor) }

  context '#set_base_documents' do
    it 'should call to #get_for_support ' do
      expect_any_instance_of(query).to receive(:get_for_support).and_return(true)
      query.new(advisor_support, { for_support: true }).set_base_documents
    end

    it 'should call to #get_document_types' do
      expect_any_instance_of(query).to receive(:get_document_types).and_return(true)
      query.new(advisor_support, {}).set_base_documents
    end
  end

  context '#pages_count' do
    let!(:pages_count) { StandardDocument.page(1).per(query::PER_PAGE).total_pages }

    it 'should return pages count if standards documents is paginate' do
      result_query = query.new(advisor_support, { for_support: true, page: 1 })
      result_query.set_base_documents

      result = result_query.pages_count

      expect(result).to eq(pages_count)
    end

    it 'should return nil if standards documents is not paginate' do
      result = query.new(advisor_support, { page: 1 }).pages_count

      expect(result).to be_nil
    end
  end

  context '#get_document_types' do
    it 'should return document types' do
      advisor_query = query.new(advisor, { client_id: client.id, client_type: 'Client' })

      result = advisor_query.get_document_types

      expect(result).not_to be_empty
      expect(result.to_a.size).to eq(StandardDocument.count)
    end

    it 'should return client-created standard' do
      standard_document = create(:standard_document, :with_consumer_owner)
      client = standard_document.owners.first.owner.client_seats.first
      advisor.clients_as_advisor << client

      advisor_query = query.new(advisor, { client_id: client.id, client_type: 'Client' })

      result = advisor_query.get_document_types

      expect(result).not_to be_empty
      expect(result).to include(standard_document)
    end

    it 'should return just own standards' do
      standard_document = create(:standard_document, :with_client_owner, :consumer_id => advisor.id)
      advisor.clients_as_advisor << standard_document.owners.first.owner

      advisor_query = query.new(advisor, { client_id: client.id, client_type: 'Client' })
      result = advisor_query.get_document_types

      expect(result).not_to be_empty

      expect(result.pluck(:name)).not_to include(standard_document.name)
    end
  end

  context '#get_document_types_for_docyt_support' do
    let!(:advisor)           { create(:advisor) }

    it 'should return standard categories if user is docyt support' do
      StandardDocument.destroy_all

      standard_document = create(:standard_document, :with_consumer_owner)

      result = query.new(advisor_support, { for_support: true, page: 1 }).set_base_documents.order(:id)

      expect(result.include?(standard_document)).to be_truthy
      expect(result.size).to eq(StandardDocument.count)
    end

    it 'should return nil if user is not docyt support' do
      result = query.new(advisor, { page: 1 }).get_document_types_for_docyt_support

      expect(result).to be_nil
    end
  end

  context '#get_client_document_types_for_docyt_support' do
    it 'should return standard_documents of uploaded client documents' do
      document_with_category = create(:document, :with_owner, uploader: connected_client.user, standard_document: StandardDocument.first)
      result = query.new(advisor_support, { for_client_id: connected_client.id }).get_client_document_types_for_docyt_support

      expect(result.first.id).to eq(document_with_category.standard_document_id)
      expect(result.first.doc_count).to eq(1)
      expect(result.length).to eq(1)
    end

    it 'should return empty relation of standard_documents if client no have uploaded documents with standard document' do
      result = query.new(advisor_support, { for_client_id: connected_client.id }).get_client_document_types_for_docyt_support

      expect(result.length).to eq(0)
    end
  end

  context '#get_for_support' do
    it 'should call to #get_client_document_types_for_docyt_support' do
      expect_any_instance_of(query).to receive(:get_client_document_types_for_docyt_support).and_return(true)
      query.new(advisor_support, { for_client_id: Faker::Number.number(2) }).get_for_support
    end

    it 'should call to #get_document_types_for_docyt_support' do
      expect_any_instance_of(query).to receive(:get_document_types_for_docyt_support).and_return(true)
      query.new(advisor_support, {}).get_for_support
    end
  end

end
