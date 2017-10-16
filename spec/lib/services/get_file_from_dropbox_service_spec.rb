require 'rails_helper'
require 'custom_spec_helper'

RSpec.describe GetFileFromDropboxService do
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
    let(:file_content) { Faker::Lorem.sentence }

    it 'downloads file from Dropbox' do
      allow_any_instance_of(::DropboxClient).to receive(:get_file)
        .with(document.cloud_service_full_path)
        .and_return(file_content)
      file = GetFileFromDropboxService.new(document, "tmp/tmp_downloads/#{document.id}").call
      expect(File.basename(file)).to eq(document.original_file_name)
      expect { file.open.read }.to raise_error(NoMethodError) # file is explicitly created as write-only as a security measure
    end
  end
end
