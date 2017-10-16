require "rails_helper"
require 'custom_spec_helper'

RSpec.describe Api::Web::V1::StandardFoldersQuery do
  before do
    load_standard_documents('standard_base_documents_structure3.json')
    load_docyt_support('standard_base_documents_structure3.json')
  end

  let!(:business_partner) { create(:business_partner, user: advisor) }

  let(:standard_group) { create(:standard_group) }
  let(:consumer)       { create(:consumer) }

  let(:connected_client) { create(:client, advisor: advisor, consumer: consumer) }
  let(:consumer_group)   { create(:group, standard_group: standard_group, owner: consumer) }
  let(:consumer_group_user) { create(:group_user, user: consumer, group: consumer_group) }

  let(:advisor)       { create(:advisor) }
  let(:client)        { create(:client, advisor: advisor) }
  let(:fake_client)   { create(:client) }
  let(:query)         { Api::Web::V1::StandardFoldersQuery }
  let(:only_category) { StandardFolder.only_category }

  context "initialize" do
    it "should have arel tables" do
      standard_folders_query = query.new(advisor, { client_id: client.id })

      expect(standard_folders_query.instance_variable_get(:@standard_folder_standard_documents)).to be_a_kind_of(Arel::Table)
      expect(standard_folders_query.instance_variable_get(:@standard_folder_standard_documents)).not_to be_nil
      expect(standard_folders_query.instance_variable_get(:@standard_folders)).to be_a_kind_of(Arel::Table)
      expect(standard_folders_query.instance_variable_get(:@standard_folders)).not_to be_nil
      expect(standard_folders_query.instance_variable_get(:@documents)).to be_a_kind_of(Arel::Table)
      expect(standard_folders_query.instance_variable_get(:@documents)).not_to be_nil
    end
  end

  context "get categories" do
    let!(:document) {
      create(:document, :with_std_doc, uploader: advisor,
        document_owners: [DocumentOwner.new(owner_id: advisor.id, owner_type: 'User')]
      )
    }

    let(:advisor_business)  { advisor.businesses.sample }

    it "should return an array of StandardFolder for client" do
      standard_folders_query = query.new(advisor, { client_id: client.id })

      result = standard_folders_query.get_categories
      expect(result).not_to be_empty
      expect(result.to_a.length).to eq(advisor.standard_category.advisor_default_folders.count)
    end

    it "should return an array of StandardFolder for group_user" do
      standard_folders_query = query.new(advisor, { contact_type: 'GroupUser', contact_id: consumer_group_user.id })

      result = standard_folders_query.get_categories
      expect(result).not_to be_empty
      expect(result.to_a.length).to eq(advisor.standard_category.advisor_default_folders.count)
    end

    it 'should return an array of StandardFolder for advisor' do
      result = query.new(advisor, { own_categories: true }).get_categories

      expect(result.length).to eq(1)
      expect(result.sample.id).to eq(document.standard_document.standard_folder.id)
    end

    it 'should return categories for business' do
      advisor_business.business_documents.create(document: document)

      categories = query.new(advisor, { business_id: advisor_business.id }).get_categories

      expect(categories.length).to eq(1)
      expect(categories.sample.id).to eq(document.standard_document.standard_folder.id)
    end
  end

  context "get category documents" do
    context "category not found" do
      it "should return empty document if category not found in client" do
        standard_folders_query = query.new(advisor, { client_id: client.id })

        result = standard_folders_query.get_category_documents

        expect(result).to be_empty
      end

      it "should return empty document if category not found in group user" do
        standard_folders_query = query.new(advisor, { contact_type: 'GroupUser', contact_id: consumer_group_user.id })

        result = standard_folders_query.get_category_documents

        expect(result).to be_empty
      end
    end

    context "empty document" do
      let(:fake_group)      { create(:group, standard_group: standard_group, owner: create(:consumer)) }
      let(:fake_group_user) { create(:unconnected_group_user, group: fake_group) }

      it "should return empty document if no client" do
        standard_folders_query = query.new(advisor, { client_id: fake_client.id })

        result = standard_folders_query.get_category_documents

        expect(result).to be_empty
      end

      it "should return empty document if no group_user" do
        standard_folders_query = query.new(advisor, { contact_type: 'GroupUser', contact_id: fake_group_user.id })

        result = standard_folders_query.get_category_documents

        expect(result).to be_empty
      end
    end

    context 'advisor documents' do
      let!(:document) {
        build(:document,
          uploader: advisor,
          document_owners: [DocumentOwner.new(owner: advisor)],
          cloud_service_authorization: CloudServiceAuthorization.first
        )
      }

      it 'should return own documents of category' do
        document.save

        standard_folders_query = query.new(advisor, { own_documents: true })
        result = standard_folders_query.get_category_documents

        expect(result.size).to eq(1)
        expect(result.sample.id).to eq(document.id)
        expect(result.sample.original_file_name).to eq(document.original_file_name)
      end

      it 'should return empty relation if no documents' do
        standard_folders_query = query.new(advisor, { own_documents: true })

        result = standard_folders_query.get_category_documents

        expect(result).to be_empty
      end
    end

    context "documents with category" do
      context "client" do
        before do
          @standard_folder = only_category.first
          @document = Document.new(FactoryGirl.attributes_for(:document))

          @document.uploader = advisor
          @document.document_owners << DocumentOwner.new(
            owner_id: @document.uploader.id,
            owner_type: 'User'
          )

          @document.document_owners << DocumentOwner.new(
            owner_id: client.id,
            owner_type: 'Client'
          )
          @standard_document_id = @standard_folder.standard_folder_standard_documents.first.standard_base_document_id
          @document.standard_document_id = @standard_document_id
          @document.save
        end

        it "should return documents of client by selected category" do
          standard_folders_query = query.new(advisor, { client_id: client.id, standard_folder_id: @standard_folder.id })

          result = standard_folders_query.get_category_documents

          expect(result).to include(@document)
          expect(result.first.standard_document_id).to eq(@standard_document_id)
          expect(@standard_folder.standard_folder_standard_documents.pluck(:standard_base_document_id)).to include(result.first.standard_document_id)
        end

        it "should return empty document with standard_folder_id if fake client " do
          standard_folders_query = query.new(advisor, { client_id: fake_client.id, standard_folder_id: @standard_folder.id })

          result = standard_folders_query.get_category_documents

          expect(result).to be_empty
        end

        it "should return correct count of documents" do
          standard_folders_query = query.new(advisor, { client_id: client.id, standard_folder_id: @standard_folder.id })

          result = standard_folders_query.get_category_documents

          expect(result.count).to eq(1)
        end

        it "should return secured documents for client" do
          document = FactoryGirl.build(:document, :with_uploader_and_owner, uploader: advisor)

          secure_folders = StandardFolder.where(id: StandardFolder::PASSWORD_FOLDER_ID)
          secure_folder = secure_folders.first

          standard_document_id = secure_folder.standard_folder_standard_documents.first.standard_base_document_id
          document.standard_document_id = secure_folder.standard_folder_standard_documents.first.standard_base_document_id
          document.save

          documents = Document.where(id: document.id)

          allow(StandardFolder).to receive_message_chain("select.group.order.where") { secure_folders }
          allow(Document).to receive_message_chain("where.where") { documents }

          standard_folders_query = query.new(advisor, { client_id: client.id, standard_folder_id: secure_folder.id, password: advisor.password })

          result = standard_folders_query.get_category_documents

          expect(result).to include(document)
          expect(result.first.standard_document_id).to eq(standard_document_id)
        end

        it "should not return secured documents for client" do
          secure_folders = StandardFolder.where(id: StandardFolder::PASSWORD_FOLDER_ID)
          documents = Document.where(id: @document.id)
          secure_folder = secure_folders.first

          standard_folders_query = query.new(advisor, { client_id: client.id, standard_folder_id: secure_folder.id, password: Faker::Lorem.word })

          result = standard_folders_query.get_category_documents

          expect(result).to be_empty
        end
      end
    end

    context "documents without category" do
      before do
        @standard_folder = only_category.first
        @document = FactoryGirl.attributes_for(:document)
        @document = Document.new(@document)

        @document.uploader = advisor
        @document.document_owners << DocumentOwner.new(
          owner_id: @document.uploader.id,
          owner_type: 'User'
        )

        @document.document_owners << DocumentOwner.new(
          owner_id: client.id,
          owner_type: 'Client'
        )
        @document.save
      end

      it "should return uncategorized documents of cliens" do
        standard_folders_query = query.new(advisor, { client_id: client.id, standard_folder_id: nil })

        result = standard_folders_query.get_category_documents

        expect(result).to include(@document)
        expect(result.first.standard_document_id).to eq(nil)
      end
    end

    context 'documents for business' do
      let(:document) {
        create(:document, uploader: advisor, standard_document: StandardDocument.first,
          document_owners: [DocumentOwner.new(owner_id: advisor.id, owner_type: 'User')]
        )
      }

      let(:standard_folder)  { document.standard_document.standard_folder }
      let(:advisor_business) { advisor.businesses.sample }

      it 'should return documents for business' do
        advisor_business.business_documents.create(document: document)

        standard_folders_query = query.new(advisor, { business_id: advisor_business.id, standard_folder_id: standard_folder.id })

        result = standard_folders_query.get_category_documents

        expect(result.size).to eq(1)
        expect(result.sample.id).to eq(document.id)
      end

      it 'should return empty relation for business' do
        standard_folders_query = query.new(advisor, { business_id: advisor_business.id, standard_folder_id: standard_folder.id })

        result = standard_folders_query.get_category_documents

        expect(result).to be_empty
      end
    end
  end

  context "get standard folder" do
    it "should return a StandardFolder" do
      standard_folders_query = query.new(advisor, { client_id: client.id, id: StandardFolder.only_category.first.id })

      result = standard_folders_query.get_standard_folder

      expect(result).not_to be_nil
      expect(result.id).to eq(StandardFolder.only_category.first.id)
    end

    it "should return nil if no params[:id]" do
      standard_folders_query = query.new(advisor, { client_id: client.id })

      result = standard_folders_query.get_standard_folder

      expect(result).to be_nil
    end
  end

  context "private" do
    before(:each) do
      @document = Document.new(FactoryGirl.attributes_for(:document))

      @document.uploader = advisor
      @document.document_owners << DocumentOwner.new(
        owner_id: @document.uploader.id,
        owner_type: 'User'
      )

      @document.document_owners << DocumentOwner.new(
        owner_id: client.id,
        owner_type: 'Client'
      )

      @document.save
    end

    context "get_query_params_for_user_document_types" do
      it "should return Client params" do
        standard_folders_query = query.new(advisor, { client_id: client.id })

        params = standard_folders_query.send(:get_query_params_for_user_document_types, client)

        expect(params[:user_id]).to eq(client.id)
        expect(params[:user_type]).to eq('Client')
      end
    end

    context "get_documents" do
      it "should return documents by without category" do
        standard_folders_query = query.new(advisor, { client_id: client.id })

        documents = standard_folders_query.send(:get_documents, client, nil)

        expect(documents.pluck(:id)).to include(@document.id)
      end

      it "should return documents with by category" do
        standard_category = only_category.first.standard_folder_standard_documents.first
        @document.update_attribute(:standard_document_id, standard_category.standard_base_document_id)

        standard_folders_query = query.new(advisor, { client_id: client.id })

        documents = standard_folders_query.send(:get_documents, client, [standard_category.standard_base_document_id])

        expect(documents.pluck(:id)).to include(@document.id)
      end
    end

    context "get_sql_for_show_documents_by_category" do
      it "should return sql with IN if ids are present" do
        standard_folders_query = query.new(advisor, { client_id: client.id })

        arel_node = standard_folders_query.send(:get_sql_for_show_documents_by_category, [1, 2, 3])

        expect(arel_node).to be_a_kind_of(Arel::Nodes::In)

        sql = arel_node.to_sql
        expect(sql).to include("IN (1, 2, 3)")
        expect(sql).to include('"documents"."standard_document_id"')
      end

      it "should return sql with IS NULL if no ids present" do
        standard_folders_query = query.new(advisor, { client_id: client.id })

        arel_node = standard_folders_query.send(:get_sql_for_show_documents_by_category, nil)

        expect(arel_node).to be_a_kind_of(Arel::Nodes::Equality)

        sql = arel_node.to_sql
        expect(sql).to include("IS NULL")
        expect(sql).to include('"documents"."standard_document_id"')
      end
    end

    context "get_standard_folder_standard_documents_sql" do
      it "should return correct sql" do
        standard_folders_query = query.new(advisor, { client_id: client.id })

        arel_node = standard_folders_query.send(:get_standard_folder_standard_documents_sql)

        expect(arel_node).to be_a_kind_of(Arel::SelectManager)

        sql = arel_node.to_sql
        expect(sql).to include('SELECT "standard_folder_standard_documents"."standard_base_document_id" FROM "standard_folder_standard_documents" WHERE "standard_folder_standard_documents"."standard_folder_id" = "standard_base_documents"."id"')
      end
    end

    context "get_standard_documents_ids_shared_with_advisor_sql" do
      it "should return correct sql" do
        standard_folders_query = query.new(advisor, { client_id: client.id })

        arel_node = standard_folders_query.send(:get_standard_documents_ids_shared_with_advisor_sql, client)

        expect(arel_node).to be_a_kind_of(Arel::SelectManager)

        sql = arel_node.to_sql
        expect(sql).to include('SELECT "documents"."standard_document_id" FROM "documents" WHERE "documents"."id" IN')
      end
    end

    context "get_standard_folder_ids_shared_with_advisor_sql" do
      it "should return correct sql" do
        standard_folders_query = query.new(advisor, { client_id: client.id })

        arel_node = standard_folders_query.send(:get_standard_folder_ids_shared_with_advisor_sql, client)

        expect(arel_node).to be_a_kind_of(Arel::SelectManager)

        sql = arel_node.to_sql
        expect(sql).to include('SELECT "standard_folder_standard_documents"."standard_folder_id" FROM "standard_folder_standard_documents" WHERE "standard_folder_standard_documents"."standard_base_document_id" IN (SELECT "documents"."standard_document_id" FROM "documents" WHERE "documents"."id" IN')
      end
    end

    context "get_advisor_default_folders_ids_sql" do
      it "should return correct sql" do
        standard_folders_query = query.new(advisor, { client_id: client.id })

        arel_node = standard_folders_query.send(:get_advisor_default_folders_ids_sql, advisor.standard_category_id)

        expect(arel_node).to be_a_kind_of(Arel::SelectManager)

        sql = arel_node.to_sql
        expect(sql).to include('SELECT "advisor_default_folders"."standard_folder_id" FROM "advisor_default_folders" WHERE')
        expect(sql).to include('"advisor_default_folders"."standard_category_id" = ', advisor.standard_category_id.to_s)
      end
    end

    context "get_only_folders_with_documents_sql" do
      it "should return correct sql" do
        standard_folders_query = query.new(advisor, { client_id: client.id })

        arel_node = standard_folders_query.send(:get_only_folders_with_documents_sql, client, advisor.standard_category_id)

        expect(arel_node).to be_a_kind_of(Arel::Nodes::Grouping)

        sql = arel_node.to_sql
        expect(sql).to include('("standard_base_documents"."id" IN (SELECT "standard_folder_standard_documents"."standard_folder_id" FROM "standard_folder_standard_documents" WHERE "standard_folder_standard_documents"."standard_base_document_id" IN (SELECT "documents"."standard_document_id" FROM "documents" WHERE "documents"."id" IN')
        expect(sql).to include(' OR "standard_base_documents"."id" IN (SELECT "advisor_default_folders"."standard_folder_id" FROM "advisor_default_folders" WHERE "advisor_default_folders"."standard_category_id" = ', advisor.standard_category_id.to_s)
      end
    end

    context "get_user_owner_id" do
      it "should return client id" do
        standard_folders_query = query.new(advisor, { client_id: client.id })

        id = standard_folders_query.send(:get_user_owner_id, client)

        expect(id).to eq(client.id)
      end

      it "should return consumer id" do
        standard_folders_query = query.new(advisor, { client_id: connected_client.id })

        id = standard_folders_query.send(:get_user_owner_id, connected_client)

        expect(id).to eq(connected_client.consumer_id)
      end

      it "should return nil if not client and not consumer" do
        standard_folders_query = query.new(advisor, { client_id: client.id })

        id = standard_folders_query.send(:get_user_owner_id, consumer)

        expect(id).to be_nil
      end
    end

    context "get_user_owner_type" do
      it "should return client id" do
        standard_folders_query = query.new(advisor, { client_id: client.id })

        type = standard_folders_query.send(:get_user_owner_type, client)

        expect(type).to eq('Client')
      end

      it "should return consumer id" do
        standard_folders_query = query.new(advisor, { client_id: connected_client.id })

        type = standard_folders_query.send(:get_user_owner_type, connected_client)

        expect(type).to eq('Consumer')
      end

      it "should return nil if not client and not consumer" do
        standard_folders_query = query.new(advisor, { client_id: client.id })

        type = standard_folders_query.send(:get_user_owner_type, consumer)

        expect(type).to be_nil
      end
    end
  end
end
