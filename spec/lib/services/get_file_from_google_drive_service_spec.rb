require 'rails_helper'
require 'custom_spec_helper'

RSpec.describe GetFileFromGoogleDriveService do
  before(:each) do
    load_startup_keys
    load_standard_documents('standard_base_documents_structure3.json')
    load_docyt_support('standard_base_documents_structure3.json')
  end

  let!(:consumer) { create(:consumer, :email => 'sid@vayuum.com', :pin => '123456', :pin_confirmation => '123456') }
  let!(:cloud_service) { create(:cloud_service)}
  let!(:cloud_service_auth) { create(:cloud_service_authorization, :user => consumer, :cloud_service => cloud_service, uid: '123') }
  let!(:document) { create(:document, :consumer_id => consumer.id, :cloud_service_authorization => cloud_service_auth, :original_file_name => Faker::Lorem.word, :cloud_service_full_path => '/tmp_folder/tmp_file.txt' ) }

  context '#call' do
    let(:temp_folder) {"tmp/tmp_downloads/#{document.id}"}
    let(:download_destination) { "#{temp_folder}/#{document.original_file_name}"}

    before do
      @fake_drive_client = double
      @file = double
    end

    it 'downloads file from Google Drive' do
      allow_any_instance_of(GoogleDriveClientBuilder).to receive(:get_client)
        .and_return(@fake_drive_client)
      allow(@fake_drive_client).to receive(:get_file)
        .with(document.cloud_service_full_path, :download_dest => download_destination)
      allow(File).to receive(:open)
        .with(download_destination)
        .and_return(@file)
      allow(@file).to receive(:close)
        .and_return(true)

      file = GetFileFromGoogleDriveService.new(document, temp_folder).call
      expect(file).to eq(@file)
    end
  end
end
