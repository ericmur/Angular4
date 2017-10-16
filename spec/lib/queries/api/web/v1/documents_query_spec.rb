require 'rails_helper'
require 'custom_spec_helper'

RSpec.describe Api::Web::V1::DocumentsQuery do
  before do
    load_standard_documents
    load_docyt_support
  end

  let!(:query) { Api::Web::V1::DocumentsQuery }

  let!(:document) { create(:document, :with_uploader_and_owner) }
  let!(:standard_category) { create(:standard_category, id: Faker::Number.number(2))  }

  let!(:advisor_with_documents)    { create(:advisor, standard_category: standard_category) }
  let!(:advisor_without_documents) { create(:advisor, standard_category: standard_category) }

  let!(:consumer) { document.uploader }

  let!(:client)  { create(:client, advisor: advisor_with_documents, consumer: consumer) }
  let!(:advisor) { create(:advisor, standard_category: standard_category) }

  let!(:client_not_consumer) { create(:client, advisor: advisor) }

  context "get documents" do
    context "without standard_folder_id" do
      it "should return documents if client have some" do
        Rails.stub(:user_password_hash) { consumer.password_hash("123456") }
        Rails.stub(:app_type) { User::MOBILE_APP }

        document.share_with(:by_user_id => consumer.id, :with_user_id => advisor_with_documents.id)
        documents = query.new(advisor_with_documents, { client_id: client.id })
          .get_documents

        expect(documents.count).to eq(1)
        expect(documents.first.id).to eq(document.id)
      end

      it "should return empty relation if client have no document" do
        documents = query.new(advisor_without_documents, { client_id: client.id }).get_documents

        expect(documents.count).to eq(0)
      end
    end

    context "with standard_folder_id" do
      before do
        ConsumerAccountType.load
        StandardBaseDocument.load
        @standard_folder = StandardFolder.only_category.first
        @document = FactoryGirl.attributes_for(:document)
        @document = Document.new(@document)

        @document.uploader = advisor
        @document.document_owners << DocumentOwner.new(
          owner_id: @document.uploader.id,
          owner_type: 'User'
        )

        @document.document_owners << DocumentOwner.new(
          owner_id: client_not_consumer.id,
          owner_type: 'Client'
        )
        @standard_document_id = @standard_folder.standard_folder_standard_documents.first.standard_base_document_id
        @document.standard_document_id = @standard_document_id
        @document.save
      end

      it "should return documents with category" do
        documents = query.new(advisor, { client_id: client_not_consumer.id, standard_folder_id: @standard_folder.id }).get_documents

        expect(documents.pluck(:standard_document_id)).not_to include(nil)
      end
    end

    context 'advisor documents' do
      let!(:document) {
        build(:document,
          uploader: advisor_with_documents,
          document_owners: [DocumentOwner.new(owner: advisor_with_documents)],
          cloud_service_authorization: CloudServiceAuthorization.first
        )
      }

      it 'should return own documents' do
        document.save

        documents = query.new(advisor_with_documents, { own_documents: true }).get_documents

        expect(documents.size).to eq(1)
        expect(documents.sample.id).to eq(document.id)
        expect(documents.sample.original_file_name).to eq(document.original_file_name)
      end

      it 'should return empty relation' do
        documents = query.new(advisor_with_documents, { own_documents: true }).get_documents

        expect(documents).to be_empty
      end

    end
    context 'for advisor support' do
      let!(:document) { create(:document, :with_standard_document) }

      it 'should return categorized documents if advisor is support' do
        allow_any_instance_of(User).to receive(:docyt_support?).and_return(true)

        documents = query.new(advisor, { for_support: true, only_categorized: true }).get_documents

        expect(documents.size).to eq(1)
        expect(documents.sample.id).to eq(document.id)
      end

      it 'should not return categorized documents if advisor is not support' do
        documents = query.new(advisor, { for_support: true, only_categorized: true }).get_documents

        expect(documents).to be_empty
      end
    end

    context 'for business' do
      let(:business) { create(:business) }
      let(:document) { create(:document, uploader: advisor) }

      it 'should return not categorized documents for business' do
        create(:business_partner, user: advisor, business: business)
        create(:business_document, document: document, business: business)

        documents = query.new(advisor, { business_id: business.id }).get_documents

        expect(documents.size).to eq(1)
        expect(documents.sample.id).to eq(document.id)
        expect(documents.sample.standard_document_id).to be_nil
      end

      it 'should not return documents if business not found' do
        documents = query.new(advisor, { business_id: business.id }).get_documents

        expect(documents).to be_empty
      end
    end

  end

  context 'get document' do
    it "should return document if client have it and it is shared with advisor" do
      Rails.stub(:user_password_hash) { consumer.password_hash("123456") }
      Rails.stub(:app_type) { User::MOBILE_APP }

      document.share_with(:by_user_id => consumer.id, :with_user_id => advisor_with_documents.id)
      found_document = query.new(advisor_with_documents, { id: document.id,  client_id: client.id })
        .get_document

      expect(found_document.id).to eq(document.id)
    end

    it "should return nil if client doesn't have/shared this document" do
      Rails.stub(:user_password_hash) { consumer.password_hash("123456") }
      Rails.stub(:app_type) { User::MOBILE_APP }

      found_document = query.new(advisor_with_documents, { id: document.id,  client_id: client.id })
        .get_document

      expect(found_document).to eq(nil)
    end
  end

  context 'search documents' do
    let!(:document_with_standard_document) { create(:document, :with_standard_document) }
    let!(:another_consumer) { document_with_standard_document.uploader }
    let!(:another_client)   { create(:client, advisor: advisor_with_documents, consumer: another_consumer) }

    it 'should return list of documents found without standard document id' do
      Rails.stub(:user_password_hash) { consumer.password_hash("123456") }
      Rails.stub(:app_type) { User::MOBILE_APP }

      document_name = document.original_file_name.split('.').first
      document.share_with(:by_user_id => consumer.id, :with_user_id => advisor_with_documents.id)
      documents = query.new(advisor_with_documents, { client_id: client.id, search_data: document_name })
        .search_documents

      expect(documents.size).to eq(1)
      expect(documents.first.id).to eq(document.id)
      expect(client.documents_ids_shared_with_advisor.include? documents.first.id).to be_truthy
    end

    it 'should return empty list of documents found without standard document id' do
      Rails.stub(:user_password_hash) { consumer.password_hash("123456") }
      Rails.stub(:app_type) { User::MOBILE_APP }

      document.share_with(:by_user_id => consumer.id, :with_user_id => advisor_with_documents.id)
      documents = query.new(advisor_with_documents, { client_id: client.id, search_data: 'zzzzzzzz' })
        .search_documents

      expect(documents).to be_empty
    end

    it 'should return list of documents found with standard document id' do
      Rails.stub(:user_password_hash) { another_consumer.password_hash("123456") }
      Rails.stub(:app_type) { User::MOBILE_APP }

      standard_document_name = document_with_standard_document.standard_document.name.split.first
      document_with_standard_document.share_with(:by_user_id => another_consumer.id, :with_user_id => advisor_with_documents.id)
      documents = query.new(advisor_with_documents, { client_id: another_client.id, search_data: standard_document_name })
        .search_documents

      expect(documents.size).to eq(1)
      expect(documents.first.attributes["standard_document_name"].include? standard_document_name).to be_truthy
    end

    it 'should return empty list of documents found with standard document id' do
      Rails.stub(:user_password_hash) { consumer.password_hash("123456") }
      Rails.stub(:app_type) { User::MOBILE_APP }

      document_with_standard_document.share_with(:by_user_id => another_consumer.id, :with_user_id => advisor_with_documents.id)
      documents = query.new(advisor_with_documents, { client_id: another_client.id, search_data: 'zzzzzzzz' })
        .search_documents

      expect(documents).to be_empty
    end
  end

  context 'get documents for contact' do
    let!(:standard_group) { create(:standard_group) }

    let!(:group) { create(:group, standard_group: standard_group, owner: consumer) }
    let!(:group_user) { create(:group_user, group: group, user: another_consumer) }
    let!(:another_group_user) { create(:group_user, group: group, user: create(:consumer)) }

    let!(:another_consumer) { document_with_standard_document.uploader }
    let!(:document_with_standard_document) { create(:document, :with_standard_document) }

    it 'should return list of documents shared between client and group user' do
      Rails.stub(:user_password_hash) { consumer.password_hash("123456") }
      Rails.stub(:app_type) { User::MOBILE_APP }

      document_with_standard_document.share_with(by_user_id: group_user.user.id, with_user_id: advisor.id)
      documents = query.new(advisor, { client_id: client.id, contact_id: group_user.id, contact_type: GroupUser.to_s, structure_type: 'flat' }).get_documents_for_contact
      documents_ids = group_user.documents_ids_shared_with_user(advisor)

      expect(documents_ids.include? documents.first.id).to be_truthy
      expect(document_with_standard_document.id).to eq(documents.first.id)
    end

    it 'should return empty list of documents' do
      Rails.stub(:user_password_hash) { consumer.password_hash("123456") }
      Rails.stub(:app_type) { User::MOBILE_APP }

      document_with_standard_document.share_with(by_user_id: another_group_user.user.id, with_user_id: another_consumer.id)
      documents = query.new(advisor, { client_id: client.id, contact_id: another_group_user.id, contact_type: GroupUser.to_s, structure_type: 'flat' }).get_documents_for_contact
      documents_ids = group_user.documents_ids_shared_with_user(consumer)

      expect(documents).to be_empty
      expect(documents_ids).to be_empty
    end
  end

end
