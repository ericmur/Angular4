require 'rails_helper'
require 'spec_helper'
require 'custom_spec_helper'

RSpec.describe PullDocumentsFromGoogleDriveService do
  before(:each) do
    stub_request(:any, /.*twilio.com.*/).to_return(status: 200)
    allow(TwilioClient).to receive_message_chain('get_instance.account.messages.create')
    load_standard_documents('standard_base_documents_structure3.json')
    load_docyt_support('standard_base_documents_structure3.json')
  end
  let(:cloud_service_path) { create(:cloud_service_path) }
  let!(:cloud_service_authorization) do
    create(
      :cloud_service_authorization,
      user: cloud_service_path.consumer,
      cloud_service: cloud_service_path.cloud_service_authorization.cloud_service,
      uid: '123'
    )
  end

  context '#call' do

    let(:query_string) {
    "
    '#{cloud_service_path.path}' in parents
    "
    }

    let(:list_files_query) {
      {
        :q => query_string,
        :page_size => 1000,
        :page_token => nil,
        :fields => 'files(id, name, mimeType, modifiedTime, version), next_page_token'
      }
    }

    let(:hash_calculation_query) {
      {
        :q => query_string,
        :order_by => 'modifiedTime',
        :page_size => 1000,
        :page_token => nil,
        :fields => 'files(id, modifiedTime, mime_type), next_page_token'
      }
    }

    before do
      @fake_drive_client = double
      @drive_file_query_results = double
      @drive_hash_query_results = double
      @file_for_file_query = double(
        :id => '1',
        :name => 'test_filename',
        :modified_time => DateTime.now.to_s,
        :mime_type => 'image/jpg',
        :version => '105'
      )

      @file_for_hashing = double(
        :id => '1',
        :modified_time => DateTime.now.to_s,
        :mime_type => 'image/jpg'
      )

      @hash_sum = Digest::MD5.hexdigest([@file_for_hashing.modified_time].to_json)

      allow(@drive_file_query_results).to receive(:files)
        .and_return([@file_for_file_query])
      allow(@drive_file_query_results).to receive(:next_page_token)
        .and_return(nil)
      allow(@drive_hash_query_results).to receive(:files)
        .and_return([@file_for_hashing])
      allow(@drive_hash_query_results).to receive(:next_page_token)
        .and_return(nil)
      allow(@fake_drive_client).to receive(:list_files)
        .with(list_files_query)
        .and_return(@drive_file_query_results)
      allow(@fake_drive_client).to receive(:list_files)
        .with(hash_calculation_query)
        .and_return(@drive_hash_query_results)
    end

    it 'create new documents' do
      allow_any_instance_of(GoogleDriveClientBuilder).to receive(:get_client)
        .and_return(@fake_drive_client)
      PullDocumentsFromGoogleDriveService.new(cloud_service_path).call

      expect(Document.exists?(
        uploader: cloud_service_path.consumer,
        cloud_service_authorization: cloud_service_path.cloud_service_authorization,
        cloud_service_full_path: @file_for_file_query.id,
        cloud_service_revision: @file_for_file_query.version,
        original_file_name: @file_for_file_query.name,
        file_content_type: @file_for_file_query.mime_type
      )).to be
      expect(cloud_service_path.hash_sum).to eq(@hash_sum)
    end

    it 'should not create documents for files with invalid mimeType' do
      @file_for_file_query = double(
        :id => '1',
        :name => 'db_dump.tar.gz',
        :mime_type => 'application/octet-stream',
        :version => '105'
      )

      allow_any_instance_of(GoogleDriveClientBuilder).to receive(:get_client)
        .and_return(@fake_drive_client)

      PullDocumentsFromGoogleDriveService.new(cloud_service_path).call

      expect(Document.exists?(
        uploader: cloud_service_path.consumer,
        cloud_service_authorization: cloud_service_path.cloud_service_authorization,
        cloud_service_full_path: @file_for_file_query.id,
        cloud_service_revision: @file_for_file_query.version,
        original_file_name: @file_for_file_query.name,
        file_content_type: @file_for_file_query.mime_type
      )).not_to be
    end

    it 'should not create documents for files with invalid mimeType' do
      @file_for_file_query = double(
        :id => '1',
        :name => 'never_gonna_give_you_up.gif',
        :mime_type => 'image/gif',
        :version => '105'
      )

      allow_any_instance_of(GoogleDriveClientBuilder).to receive(:get_client)
        .and_return(@fake_drive_client)

      PullDocumentsFromGoogleDriveService.new(cloud_service_path).call

      expect(Document.exists?(
        uploader: cloud_service_path.consumer,
        cloud_service_authorization: cloud_service_path.cloud_service_authorization,
        cloud_service_full_path: @file_for_file_query.id,
        cloud_service_revision: @file_for_file_query.version,
        original_file_name: @file_for_file_query.name,
        file_content_type: @file_for_file_query.mime_type
      )).not_to be
    end

    it "should only scan folder if folder hash has changed"

    it "should only update the existing document filename, revision, content_type instead of creating a new one if one already exists - only if hash has changed"

    it "should not update an existing document if its revision has not changed"

  end
end
