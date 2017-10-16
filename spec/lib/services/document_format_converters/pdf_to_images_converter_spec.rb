require 'rails_helper'
require 'spec_helper'
require 'custom_spec_helper'

RSpec.describe DocumentFormatConverters::PdfToImagesConverter do

  context '#convert' do
    before(:each) do
      messages = double()
      allow(messages).to receive(:create)
      account = double()
      allow(account).to receive(:messages) { messages }
      twilio_obj = double()
      allow(twilio_obj).to receive(:account) { account }
      TwilioClient.stub(:get_instance) { twilio_obj }
      load_standard_documents('standard_base_documents_structure3.json')
      load_docyt_support('standard_base_documents_structure3.json')
      allow_any_instance_of(DocumentFormatConverters::PageThumbnailConverter).to receive(:convert)
      allow_any_instance_of(Document).to receive(:s3_object_exists?).and_return(true)
    end

    let(:document) { create(:document, :with_uploader_and_owner, :with_system_symmetric_key) }
    let!(:test_pdf_location)   { './spec/data/test_file.pdf' }
    let!(:test_pdf_page_count) { 2 }
    
    it 'should succesfully generate .jpg pages for document and revoke system key' do
      expect(document.symmetric_keys.for_user_access(nil).count).to eq(1)
      converter = DocumentFormatConverters::PdfToImagesConverter.new(document)
      converter.instance_variable_set(:@temp_pdf_location, test_pdf_location)

      allow_any_instance_of(S3::DataEncryption).to receive(:download)
        .with(document.final_file_key, test_pdf_location).and_return(true)
      allow_any_instance_of(S3::DataEncryption).to receive(:upload)
        .with(any_args).and_return(true)
      response = double("response")
      allow(response).to receive(:body).and_return("1").twice
      
      allow_any_instance_of(Aws::S3::Object).to receive(:get).and_return(response)
      allow_any_instance_of(Page).to receive(:s3_object_exists?).and_return(true)

      document.state = 'converting'
      document.save

      converter.convert

      expect(document.pages.count).to eq(test_pdf_page_count)
      expect(document.symmetric_keys.for_user_access(nil).count).to eq(0)
    end

    it 'should raise error and should not revoke system key when downloaded pdf has wrong mime-type' do
      converter = DocumentFormatConverters::PdfToImagesConverter.new(document)
      expect(document.symmetric_keys.for_user_access(nil).count).to eq(1)
      invalid_pdf_file_location = './spec/data/standard_base_documents_structure1.json'
      converter.instance_variable_set(:@temp_pdf_location, invalid_pdf_file_location)

      allow_any_instance_of(S3::DataEncryption).to receive(:download)
        .with(document.final_file_key, invalid_pdf_file_location).and_return(true)
      allow_any_instance_of(S3::DataEncryption).to receive(:upload)
        .with(any_args).and_return(true)

      expect { converter.convert }.to raise_error
      expect(document.symmetric_keys.for_user_access(nil).count).to eq(1)
    end

    it 'should raise error and should not revoke system key when final_file_key has wrong extension' do
      document.update(final_file_key: 'test.jpg')
      converter = DocumentFormatConverters::PdfToImagesConverter.new(document)
      # set pdf path to our test pdf file using metaprogramming
      converter.instance_variable_set(:@temp_pdf_location, test_pdf_location)

      allow_any_instance_of(S3::DataEncryption).to receive(:download)
        .with(document.final_file_key, test_pdf_location).and_return(true)
      allow_any_instance_of(S3::DataEncryption).to receive(:upload)
        .with(any_args).and_return(true)

      expect { converter.convert }.to raise_error
      expect(document.symmetric_keys.for_user_access(nil).count).to eq(1)
    end
  end

end
