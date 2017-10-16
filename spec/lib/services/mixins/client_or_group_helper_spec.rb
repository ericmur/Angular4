require "rails_helper"
require 'custom_spec_helper'

RSpec.describe Mixins::ClientOrGroupUserHelper do

  before(:each) do
    load_standard_documents('standard_base_documents_structure3.json')
    load_docyt_support('standard_base_documents_structure3.json')
  end

  let!(:another_client)   { create(:client, advisor: advisor, name: Faker::Name::first_name, consumer: consumer) }
  let!(:business_partner) { create(:business_partner, user: advisor) }

  let(:client_or_group_helper) { Class.new { extend Mixins::ClientOrGroupUserHelper } }

  let(:client)      { create(:client, advisor: advisor, name: Faker::Name::first_name) }
  let(:advisor)     { create(:advisor, standard_category: StandardCategory.first) }
  let(:consumer)    { create(:consumer) }
  let(:fake_client) { create(:client) }

  let(:consumer_group)      { create(:group, standard_group: create(:standard_group), owner: consumer) }
  let(:consumer_group_user) { create(:group_user, group: consumer_group) }

  context "get_client" do
    it "should return client only belonged to advisor" do
      advisor_client = client_or_group_helper.get_client(advisor, client.id)

      expect(advisor_client.id).to eq(client.id)
      expect(advisor_client).to be_a_kind_of(Client)
      expect(advisor_client).not_to be_nil
    end

    it "should return nil if fake client" do
      advisor_client = client_or_group_helper.get_client(advisor, fake_client.id)

      expect(advisor_client).to be_nil
    end
  end

  context "get_group_user" do
    it "should find group_user" do
      group_user = client_or_group_helper.get_group_user(advisor, consumer_group_user.id)

      expect(group_user.id).to eq(consumer_group_user.id)
      expect(group_user).to be_a_kind_of(GroupUser)
      expect(group_user).not_to be_nil
    end

    it "should return nil if group user not exist" do
      Client.find_by(consumer_id: consumer.id, advisor_id: advisor.id).destroy

      group_user = client_or_group_helper.get_group_user(advisor, Faker::Number.number(3))

      expect(group_user).to be_nil
    end

    it "should return nil if consumer not connected to advisor and current workspace is business" do
      advisor.update(current_workspace_id: ConsumerAccountType::BUSINESS)

      Client.find_by(consumer_id: consumer.id, advisor_id: advisor.id).destroy

      group_user = client_or_group_helper.get_group_user(advisor, consumer_group_user.id)

      expect(group_user).to be_nil
    end

    it "should return group_user if he is connected to group, owner which is advisor " do
      consumer_group.update(owner: advisor)

      group_user = client_or_group_helper.get_group_user(advisor, consumer_group_user.id)

      expect(group_user.id).to eq(consumer_group_user.id)
    end
  end

  context "check_contact_type" do
    it "should raise error if contact type not Client and not GroupUser" do
      params = { contact_type: "FakeClass", contact_id: 0 }

      expect {
        client_or_group_helper.check_contact_type(params)
      }.to raise_error(RuntimeError, /Invalid type: FakeClass/)
    end

    it "should raise_error if fake contact_id and contact_type Client" do
      params = { contact_type: "Client" }

      expect {
        client_or_group_helper.check_contact_type(params)
      }.not_to raise_error
    end

    it "should raise_error if fake contact_id and contact_type GroupUser" do
      params = { contact_type: "GroupUser" }

      expect {
        client_or_group_helper.check_contact_type(params)
      }.not_to raise_error
    end
  end

  context "set_group_user_from_params" do
    it "should return contact_id if contact_type: GroupUser" do
      params = { contact_id: consumer_group_user.id, contact_type: GroupUser.to_s }

      contact_group_user_id = client_or_group_helper.set_group_user_from_params(params)

      expect(contact_group_user_id).to eq(consumer_group_user.id)
    end

    it "should return nil if params are blank" do
      params = {  }

      contact_group_user_id = client_or_group_helper.set_group_user_from_params(params)

      expect(contact_group_user_id).to be_nil
    end

    it "should return nil if client_id is blank" do
      params = { client_id: nil }

      contact_group_user_id = client_or_group_helper.set_group_user_from_params(params)

      expect(contact_group_user_id).to be_nil
    end

    it "should return nil if contact_id is blank" do
      params = { contact_id: nil }

      contact_group_user_id = client_or_group_helper.set_group_user_from_params(params)

      expect(contact_group_user_id).to be_nil
    end

    it "should raise error if unknown type" do
      params = { contact_id: consumer_group_user.id, contact_type: 'FakeClass' }

      expect {
        client_or_group_helper.set_group_user_from_params(params)
      }.to raise_error(RuntimeError, /Invalid type: FakeClass/)
    end
  end

  context "set_client_from_params" do
    it "should return client_id if params have client_id" do
      params = { client_id: client.id }

      client_id = client_or_group_helper.set_client_from_params(params)

      expect(client_id).to eq(client.id)
    end

    it "should return contact_id if contact_type: Client" do
      params = { contact_id: client.id, contact_type: Client.to_s }

      contact_client_id = client_or_group_helper.set_client_from_params(params)

      expect(contact_client_id).to eq(client.id)
    end

    it "should return nil if params are blank" do
      params = {  }

      contact_client_id = client_or_group_helper.set_client_from_params(params)

      expect(contact_client_id).to be_nil
    end

    it "should return nil if client_id is blank" do
      params = { client_id: nil }

      contact_client_id = client_or_group_helper.set_client_from_params(params)

      expect(contact_client_id).to be_nil
    end

    it "should return nil if contact_id is blank" do
      params = { contact_id: nil }

      contact_client_id = client_or_group_helper.set_client_from_params(params)

      expect(contact_client_id).to be_nil
    end

    it "should raise error if unknown type" do
      params = { contact_id: client.id, contact_type: 'FakeClass' }

      expect {
        client_or_group_helper.set_client_from_params(params)
      }.to raise_error(RuntimeError, /Invalid type: FakeClass/)
    end
  end

  context "get_shared_ids_by_object" do
    let!(:document) {
      create(:document, uploader: advisor, standard_document: StandardDocument.first,
        document_owners: [DocumentOwner.new(owner: advisor)]
      )
    }

    let(:advisor_business) { advisor.businesses.sample }

    let!(:document_advisor_client) do
      document = Document.new(FactoryGirl.attributes_for(:document))

      document.uploader = advisor
      document.document_owners =
        [DocumentOwner.new(owner: document.uploader), DocumentOwner.new(owner: client)]

      document.save
      document
    end

    let!(:document_advisor_consumer) do
      document = Document.new(FactoryGirl.attributes_for(:document))

      document.uploader = consumer
      document.document_owners =
        [DocumentOwner.new(owner: document.uploader), DocumentOwner.new(owner: advisor)]

      document.save
      document
    end

    let!(:document_advisor) do
      document = Document.new(FactoryGirl.attributes_for(:document))

      document.uploader = advisor
      document.document_owners = [DocumentOwner.new(owner: document.uploader)]

      document.save
      document
    end

    let!(:document_advisor_group_user) do
      document = Document.new(FactoryGirl.attributes_for(:document))

      document.uploader = consumer_group_user.user
      document.document_owners =
        [DocumentOwner.new(owner: document.uploader), DocumentOwner.new(owner: advisor)]

      document.save
      document
    end

    it "should raise error if object type not Client and not GroupUser" do
      expect{
        client_or_group_helper.get_shared_ids_by_object(advisor, consumer)
      }.to raise_error(RuntimeError, /Invalid type: User/)
    end

    it "should return ids shared documents for advisor and client" do
      ids = client_or_group_helper.get_shared_ids_by_object(advisor, client)

      expect(ids).to include(document_advisor_client.id)
    end

    it "should return ids shared documents for advisor and group user" do
      ids = client_or_group_helper.get_shared_ids_by_object(advisor, consumer_group_user)

      expect(ids).to include(document_advisor_group_user.id)
    end

    it 'should return own documents ids for advisor if its equal to the object' do
      ids = client_or_group_helper.get_shared_ids_by_object(document_advisor.uploader, document_advisor.uploader)

      expect(ids).to include(document_advisor.id)
      expect(ids.size).to eq(5)
    end

    it 'should return document ids for business' do
      advisor_business.business_documents.create(document: document)

      ids = client_or_group_helper.get_shared_ids_by_object(advisor, advisor_business)

      expect(ids).to include(document.id)
      expect(ids.size).to eq(1)
    end
  end

  context "set_user_object" do
    it "should return client" do
      object = client_or_group_helper.set_user_object(advisor, client.id, nil)

      expect(object).to be_a_kind_of(Client)
      expect(object.id).to eq(client.id)
    end

    it "should return nil if fake_client" do
      object = client_or_group_helper.set_user_object(advisor, fake_client.id, nil)

      expect(object).to be_nil
    end

    it "should return group_user" do
      object = client_or_group_helper.set_user_object(advisor, nil, consumer_group_user.id)

      expect(object).to be_a_kind_of(GroupUser)
      expect(object.id).to eq(consumer_group_user.id)
    end

    it "should return nil if group_user not found" do
      object = client_or_group_helper.set_user_object(advisor, nil, 0)

      expect(object).to be_nil
    end

    it "should return nil if no client and no group user" do
      object = client_or_group_helper.set_user_object(advisor, nil, nil)

      expect(object).to be_nil
    end
  end
end
