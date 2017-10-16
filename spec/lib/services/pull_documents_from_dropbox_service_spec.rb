require 'rails_helper'
require 'spec_helper'
require 'custom_spec_helper'

RSpec.describe PullDocumentsFromDropboxService do
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
    let(:api_files_data) {
      [
        {
          'path' => '/test_path1/test_file1.text',
          'revision' => 13,
          'mime_type' => 'image/jpg'
        },
        {
          'path' => '/test_path2/test_file2.text',
          'revision' => 777,
          'mime_type' => 'image/jpg'
        },
        {
          'path' => '/test_path3/test_file3.text',
          'revision' => 5,
          'mime_type' => 'image/jpg'
        }
      ]
    }

    let(:api_files_data_with_invalid_mime_type) {
      {
        'contents' => [
          {
            'path' => '/test_path1/spreadsheet.xls',
            'revision' => 13,
            'mime_type' => 'application/x-vnd.oasis.opendocument.spreadsheet'
          },
          {
            'path' => '/test_path2/script.json',
            'revision' => 777,
            'mime_type' => 'application/vnd.google-apps.script+json'
          },
          {
            'path' => '/test_path2/never_gonna_give_you_up.gif',
            'revision' => 777,
            'mime_type' => 'image/gif'
          },
          {
            'path' => '/test_path3/unix_kernel',
            'revision' => 5,
            'mime_type' => 'application/octet-stream'
          }
        ]
      }
    }

    let(:api_data_service_path) {
      {
        'contents' => [
          {
            'is_dir' => false,
            'path' => api_files_data[0]['path'],
            'revision' => api_files_data[0]['revision'],
            'mime_type' => 'image/jpg',
            'modified' => 'Fri, 05 Feb 2016 20:35:36 +0000'
          },
          {
            'is_dir' => false,
            'path' => api_files_data[1]['path'],
            'revision' => api_files_data[1]['revision'],
            'mime_type' => 'image/jpg',
            'modified' => 'Sat, 06 Feb 2016 20:35:36 +0000'
          },
          {
            'is_dir' => true,
            'path' => 'test_path3'
          }
        ]
      }
    }

    let(:api_inner_folder_data_service_path) {
      {
        'contents' => [
          {
            'is_dir' => false,
            'path' => api_files_data[2]['path'],
            'revision' => api_files_data[2]['revision'],
            'mime_type' => 'image/jpg',
            'modified' => 'Sat, 06 Feb 2016 20:35:36 +0000'
          }
        ]
      }
    }

    it 'create new documents' do
      allow_any_instance_of(::DropboxClient).to receive(:metadata)
        .with(cloud_service_path.path)
        .and_return(api_data_service_path)
      allow_any_instance_of(::DropboxClient).to receive(:metadata)
        .with(api_data_service_path['contents'].last['path'])
        .and_return(api_inner_folder_data_service_path)

      PullDocumentsFromDropboxService.new(cloud_service_path).call

      api_files_data.each do |api_file_data|
        expect(Document.exists?(
          uploader: cloud_service_path.consumer,
          cloud_service_authorization: cloud_service_path.cloud_service_authorization,
          cloud_service_full_path: api_file_data['path'],
          cloud_service_revision: api_file_data['revision'],
          file_content_type: api_file_data['mime_type']
        )).to be
      end
    end

    it 'should not create documents for files with invalid mimeType' do
      allow_any_instance_of(::DropboxClient).to receive(:metadata)
        .with(cloud_service_path.path)
        .and_return(api_files_data_with_invalid_mime_type)

      PullDocumentsFromDropboxService.new(cloud_service_path).call

      api_files_data_with_invalid_mime_type['contents'].each do |api_file_data|
        expect(Document.exists?(
          uploader: cloud_service_path.consumer,
          cloud_service_authorization: cloud_service_path.cloud_service_authorization,
          cloud_service_full_path: api_file_data['path'],
          cloud_service_revision: api_file_data['revision'],
          file_content_type: api_file_data['mime_type']
        )).not_to be
      end
    end

    it 'should only scan folder if folder hash has changed' 
  
    it "should only update hash_sum for existing document instead of creating a new one if one already exists - only if hash has changed"

    it "should not update an existing document if its revision has not changed"
  end
end
