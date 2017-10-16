require 'rails_helper'
require 'custom_spec_helper'

RSpec.describe S3DocumentUploaderService do
  before(:each) do
    load_startup_keys
    load_standard_documents('standard_base_documents_structure3.json')
    load_docyt_support('standard_base_documents_structure3.json')
  end
  let!(:consumer) { create(:consumer, :email => 'sid@vayuum.com', :pin => '123456', :pin_confirmation => '123456') }
  let!(:document) { create(:document, :consumer_id => consumer.id, :cloud_service_full_path => 'identity_docs/drivers_license.pdf', :share_with_system => true) }
  let(:file) { Tempfile.new('test') }

  let(:s3_response) { double }

  context '#call' do
    let(:file_content) { Faker::Lorem.sentence }

    it 'uploads encrypted file to s3' do
      file.open.write(file_content)
      object_key = [document.id, document.original_file_name].join('-')

      allow_any_instance_of(S3::DataEncryption).to receive(:upload)
        .with(file.path, { object_key: object_key })
        .and_return(s3_response)
      document.stub(:s3_object_exists?) { true }
      document.start_upload!
      response = S3DocumentUploaderService.new(document, file).call
      expect(response).to eq true
    end
  end
end
