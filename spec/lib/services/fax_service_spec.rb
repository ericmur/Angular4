require 'rails_helper'
require 'spec_helper'
require 'custom_spec_helper'
require 's3'

RSpec.describe FaxService do
  before do
    Rails.set_app_type(User::WEB_APP)
    load_standard_documents
    load_docyt_support

    allow_any_instance_of(SymmetricKey).to receive(:decrypt_key).and_return(Faker::Code.ean)
    allow_any_instance_of(SymmetricKey).to receive(:decrypt_iv).and_return(Faker::Code.ean)
    allow_any_instance_of(S3::DataEncryption).to receive(:download).and_return(true)
    allow(File).to receive(:new).and_return(test_pdf_location)
    allow(File).to receive(:delete).and_return(true)
  end

  let!(:service)  { FaxService }
  let!(:sender)   { document.uploader }
  let!(:message)   { Faker::Lorem.sentence }
  let!(:phaxio_id) { Faker::Number.number(8) }

  let!(:test_pdf_location) { File.new('./spec/data/test_file.pdf') }

  let!(:success_response) {
    OpenStruct.new(
      {
        faxId: phaxio_id,
        parsed_response: {
          'success' => true,
          'message' => message
        }
      }
    )
  }

  let!(:failed_response) {
    OpenStruct.new(
      {
        parsed_response: {
          'success' => false,
          'message' => message
        }
      }
    )
  }

  context '#download_document_and_send_fax' do
    let!(:document)  { create(:document, :with_uploader_and_owner, :with_system_symmetric_key, :with_standard_document) }
    let!(:fax)       { create(:fax, sender: sender, document: document) }

    it 'should update fax with status and uniq faxio id if successful sent' do
      allow(Phaxio).to receive(:send_fax) { success_response }

      service.new(fax.id).download_document_and_send_fax

      fax.reload

      expect(fax.status).to eq('sending')
      expect(fax.status_message).to eq(message)
      expect(fax.phaxio_id.to_s).to eq(phaxio_id)
    end

    it 'should update fax with status and error message if unsuccessful sent' do
      allow(Phaxio).to receive(:send_fax) { failed_response }

      expect{
        service.new(fax.id).download_document_and_send_fax
      }.to raise_error(StandardError)

      fax.reload

      expect(fax.status).to eq('failed')
      expect(fax.status_message).to eq(message)
    end
  end

  context '#search_sending_faxes_and_update_status' do
    let!(:document)  { create(:document, :with_uploader_and_owner, :with_system_symmetric_key, :with_standard_document) }
    let!(:sending_fax) { create(:fax, sender: sender, document: document, status: 'sending') }

    it 'should found faxes with status sending and update them status by phaxio_id' do
      allow(Phaxio).to receive(:get_fax_status) { success_response }

      expect{
        service.search_sending_faxes_and_update_status
      }.to change{ SymmetricKey.count }.by(-1)

      sending_fax.reload

      expect(sending_fax.status).to eq('sent')
      expect(sending_fax.status_message).to eq(success_response.parsed_response['message'])
    end
  end
end
