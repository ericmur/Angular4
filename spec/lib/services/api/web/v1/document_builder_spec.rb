require 'rails_helper'
require 'spec_helper'
require 'custom_spec_helper'

RSpec.describe Api::Web::V1::DocumentBuilder do
  before do
    stub_request(:any, /.*twilio.com.*/).to_return(status: 200)
    allow(TwilioClient).to receive_message_chain('get_instance.account.messages.create')
      .and_return(true)
    load_standard_documents('standard_base_documents_structure3.json')
    load_docyt_support('standard_base_documents_structure3.json')
  end

  let(:group)    { create(:group, owner: consumer) }
  let(:client)   { create(:client, advisor: advisor, consumer: consumer) }
  let(:advisor)  { create(:advisor) }
  let(:consumer) { document_with_owner.uploader}
  let(:business) { create(:business) }

  let(:document_with_owner) { create(:document, :with_uploader_and_owner) }

  let(:unconnected_client)   { create(:client, advisor: advisor) }

  let(:group_user) { create(:group_user, group: group) }
  let(:unconnected_group_user) { create(:group_user, group: group, user: nil) }

  let(:service)  { Api::Web::V1::DocumentBuilder }

  context "#create_document" do
    let(:valid_document_params) {
      {
        "original_file_name" => "#{Faker::Lorem.word}.png",
        "storage_size"=> Faker::Number.number(4).to_s,
        "file_content_type"=> "image/png",
      }
    }

    let(:invalid_document_params) {
      {
        "original_file_name" => "#{Faker::Lorem.word}.png",
        "storage_size"=> Faker::Number.number(4).to_s,
        "file_content_type"=> "image/png",
      }
    }

    it "should create document and return it" do
      params = { 'document' =>
        { 'client_id' => client.id, "document_owners"=> [{ "owner_type"=>"Consumer", "owner_id"=> client.consumer_id }] }
      }

      expect {
        @document = service.new(advisor, valid_document_params, params).create_document
      }.to change(Document, :count).by(1)

      expect(@document.original_file_name).to eq(valid_document_params["original_file_name"])
      expect(@document.storage_size.to_s).to eq(valid_document_params['storage_size'])
      expect(@document.file_content_type).to eq(valid_document_params['file_content_type'])

      expect(@document.uploader.advisor?).not_to eq(nil)
      expect(@document.document_owners.map(&:owner_id)).to include(consumer.id)
    end

    it "should create document with owner connected group user and return it" do
      Rails.stub(:user_password_hash) { consumer.password_hash("123456") }
      Rails.stub(:app_type) { User::WEB_APP }

      params = { 'document' =>
        { 'client_id' => client.id, "document_owners"=> [{ "owner_type"=>"GroupUser", "owner_id"=> group_user.id }] }
      }

      expect {
        @document = service.new(advisor, valid_document_params, params).create_document
      }.to change(Document, :count).by(1)

      expect(@document.original_file_name).to eq(valid_document_params["original_file_name"])
      expect(@document.storage_size.to_s).to eq(valid_document_params['storage_size'])
      expect(@document.file_content_type).to eq(valid_document_params['file_content_type'])

      expect(@document.uploader.advisor?).not_to eq(nil)
      expect(@document.document_owners.map(&:owner_id)).to include(group_user.user_id)
    end

    it "should create document with unconnected group user and return it" do
      params = { 'document' =>
        { 'client_id' => client.id, "document_owners"=> [{ "owner_type"=>"GroupUser", "owner_id"=> unconnected_group_user.id }] }
      }

      expect {
        @document = service.new(advisor, valid_document_params, params).create_document
      }.to change(Document, :count).by(1)

      expect(@document.original_file_name).to eq(valid_document_params["original_file_name"])
      expect(@document.storage_size.to_s).to eq(valid_document_params['storage_size'])
      expect(@document.file_content_type).to eq(valid_document_params['file_content_type'])

      expect(@document.uploader.advisor?).not_to eq(nil)
      expect(@document.document_owners.map(&:owner_id)).to include(unconnected_group_user.id)
    end

    it "should create document with owner unconnected client and return it" do
      params = { 'document' =>
        { 'client_id' => client.id, "document_owners"=> [{ "owner_type"=>"Client", "owner_id"=> unconnected_client.id }] }
      }

      expect {
        @document = service.new(advisor, valid_document_params, params).create_document
      }.to change(Document, :count).by(1)

      expect(@document.original_file_name).to eq(valid_document_params["original_file_name"])
      expect(@document.storage_size.to_s).to eq(valid_document_params['storage_size'])
      expect(@document.file_content_type).to eq(valid_document_params['file_content_type'])

      expect(@document.uploader.advisor?).not_to eq(nil)
      expect(@document.document_owners.map(&:owner_id)).to include(unconnected_client.id)
    end

    it "should not create document and return document with errors" do
      params = { 'document' =>
        { 'client_id' => client.id, "document_owners"=> [{ "owner_type"=> "root", "owner_id"=> advisor.id }] }
      }

      expect {
        @document = service.new(advisor, invalid_document_params, params).create_document
      }.not_to change(Document, :count)

      expect(@document.errors.messages).to eq({:base=>["No document owner provided when uploading the document"]})
    end
  end

  context '#complete_upload' do
    before do
      Rails.stub(:user_password_hash) { consumer.password_hash("123456") }
      Rails.stub(:app_type) { User::MOBILE_APP }
    end

    let(:valid_upload_params) {
      {
        "final_file_key" => "#{Faker::Lorem.word}.png",
        "s3_object_key" => "#{Faker::Lorem.word}.png"
      }
    }

    let(:invalid_upload_params) {
      {
        "final_file_key" => "",
        "s3_object_key" => ""
      }
    }

    it 'should update document path on s3 and return document when params valid' do
      document_with_owner.share_with(by_user_id: consumer.id, with_user_id: advisor.id)

      params = { 'document' => { 'client_id' => client.id, 'id' => document_with_owner.id }}

      document = service.new(advisor, valid_upload_params, params).complete_document_upload

      expect(document.final_file_key).to eq(valid_upload_params['final_file_key'])
      expect(document.original_file_key).to eq(valid_upload_params['s3_object_key'])
    end

    it 'should return document with set errors when s3_object_key is invalid' do
      document_with_owner.share_with(by_user_id: consumer.id, with_user_id: advisor.id)

      params = { 'document' => { 'client_id' => client.id, 'id' => document_with_owner.id }}

      document = service.new(advisor, invalid_upload_params, params).complete_document_upload

      expect(document.errors.messages).to eq({:original_file_key =>["S3 file path is not set"]})
    end
  end

  context '#update_category' do
    before do
      ConsumerAccountType.load
      StandardBaseDocument.load

      Rails.stub(:user_password_hash) { consumer.password_hash("123456") }
      Rails.stub(:app_type) { User::MOBILE_APP }

      allow_any_instance_of(SymmetricKey).to receive(:decrypt_key).and_return(Faker::Code.ean)
      allow_any_instance_of(SymmetricKey).to receive(:decrypt_iv).and_return(Faker::Code.ean)
    end

    let!(:valid_category_params) {
      {
        "document" => {
          "client_id" => client.id, "id" => document_with_owner.id,
          "standard_document" => { "id" => StandardDocument.last.id }
        }
      }
    }

    let(:new_category_params) {
      {
        "document" => {
          "client_id" => client.id, "id" => document_with_owner.id,
          "standard_document" => { "name" => Faker::Lorem.word, "is_user_created" => true }
        }
      }
    }

    let(:invalid_category_params) {
      {
        "document" => {
          "client_id" => client.id, "id" => document_with_owner.id,
          "standard_document" => { "id" => StandardDocument.last.id+1 }, # unexisting document id
        }
      }
    }

    it 'should update document standard_document_id if category exists' do
      document_with_owner.share_with(by_user_id: consumer.id, with_user_id: advisor.id)

      document = service.new(advisor, {}, valid_category_params).update_category

      expect(document.standard_document_id).to eq(valid_category_params['document']['standard_document']['id'])
    end

    it 'should raise error if StandardDocument with this id does not exist' do
      document_with_owner.share_with(by_user_id: consumer.id, with_user_id: advisor.id)

      expect { service.new(advisor, {}, invalid_category_params).update_category }.to raise_error
    end

    it 'should raise error if StandardDocument with this id does not exist' do
      document_with_owner.share_with(by_user_id: consumer.id, with_user_id: advisor.id)

      expect { service.new(advisor, {}, invalid_category_params).update_category }.to raise_error
    end

    it 'should create a StandardDocument and assign it to document' do
      allow_any_instance_of(Document).to receive(:business_document?).and_return(true)
      document_with_owner.share_with(by_user_id: consumer.id, with_user_id: advisor.id)

      expect {
        @document = service.new(advisor, {}, new_category_params).update_category
        }.to change(StandardDocument, :count)

      expect(@document.standard_document_id).to eq(StandardDocument.last.id)
    end

    it 'should create owner advisor for temporary document' do
      document = create(:document, state: 'uploaded', uploader: advisor, source: Chat::SOURCE[:web_chat])

      params =
        {
          'document' => {
            'temporary' => true,
            'client_id' => client.id, 'id' => document.id,
            'standard_document' => { 'id' => StandardDocument.last.id },
            'document_owners'=> [{ 'owner_type'=> advisor.class.name.to_s, 'owner_id'=> advisor.id }]
          }
        }

      expect { service.new(advisor, {}, params).update_category }.to change(DocumentOwner, :count)

      document.reload
      expect(document.state).to eq('converting')
      expect(document.document_owners.count).to eq(1)
      expect(document.document_owners.first.owner_id).to eq(advisor.id)
      expect(document.standard_document_id).to eq(params['document']['standard_document']['id'])
    end

    it 'should create owner consumer for temporary document' do
      document = create(:document, state: 'uploaded', uploader: consumer, source: Chat::SOURCE[:web_chat])
      document.share_with(by_user_id: consumer.id, with_user_id: advisor.id)

      params =
        {
          'document' => {
            'temporary' => true,
            'client_id' => client.id, 'id' => document.id,
            'standard_document' => { 'id' => StandardDocument.last.id },
            'document_owners'=> [{ 'owner_type'=> consumer.class.name.to_s, 'owner_id'=> consumer.id }]
          }
        }

      expect { service.new(advisor, {}, params).update_category }.to change(DocumentOwner, :count)

      document.reload
      expect(document.state).to eq('converting')
      expect(document.document_owners.count).to eq(1)
      expect(document.document_owners.first.owner_id).to eq(consumer.id)
      expect(document.standard_document_id).to eq(params['document']['standard_document']['id'])
    end

    context 'for business document' do
      before do
        allow_any_instance_of(Document).to receive(:business_document?).and_return(true)
        create(:business_partner, user: advisor, business: business)
        create(:business_document, business: business, document: document)
        document.share_with(by_user_id: consumer.id, with_user_id: advisor.id)
      end

      let(:document) { create(:document, state: 'uploaded', uploader: consumer) }
      let(:user_standard_document) { create(:standard_document, :with_consumer_owner) }

      it 'should update category and create user folder settings for business document' do
        params =
          {
            'document' => {
              'business_id' => business.id, 'id' => document.id,
              'standard_document' => { 'id' => StandardDocument.last.id },
            }
          }

        expect { service.new(advisor, {}, params).update_category }.to change(UserFolderSetting, :count).by(2)
        document.reload
        expect(document.standard_document_id).to eq(params['document']['standard_document']['id'])
      end

      it 'should update category and create owners for business document' do
        params =
          {
            'document' => {
              'business_id' => business.id, 'id' => document.id,
              "standard_document" => { "id" => user_standard_document.id },
            }
          }

        expect { service.new(advisor, {}, params).update_category }.to change(StandardBaseDocumentOwner, :count).by(1)

        document.reload
        expect(document.standard_document_id).to eq(params['document']['standard_document']['id'])
      end
    end
  end

end
