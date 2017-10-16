require 'rails_helper'
require 'spec_helper'
require 'custom_spec_helper'

RSpec.describe DocumentFormatConverters::ImagesToPdfConverter do

  context '#convert' do
    before(:each) do
      stub_request(:any, /.*twilio.com.*/).to_return(status: 200)
      allow(TwilioClient).to receive_message_chain('get_instance.account.messages.create')
        .and_return(true)
      allow_any_instance_of(Document).to receive(:s3_object_exists?).and_return(true)
      load_standard_documents('standard_base_documents_structure3.json')
      load_docyt_support('standard_base_documents_structure3.json')
    end
    
    let!(:document) { create(:document, :with_uploader_and_owner, :with_system_symmetric_key) }
    let!(:page)     { create(:page, document: document, s3_object_key: 'sample_document_page_image.jpg') }
    let!(:test_image_location) { './spec/data/' }
    let!(:test_pdf_location) { "#{test_image_location}document-#{document.id}.pdf" }

    after(:each) do
      FileUtils.rm(test_pdf_location) if File.exists?(test_pdf_location)
    end

    it 'should succesfully generate .pdf file for document and revoke system key' do
      document.reload
      expect(document.symmetric_keys.for_user_access(nil).count).to eq(1)

      allow_any_instance_of(DocumentFormatConverters::PageThumbnailConverter).to receive(:convert)

      converter = DocumentFormatConverters::ImagesToPdfConverter.new(document)
      converter.instance_variable_set(:@temp_folder_location, test_image_location)
      converter.instance_variable_set(:@temp_pdf_location, test_pdf_location)

      allow(FileUtils).to receive(:mkdir_p).with(any_args)
        .and_return(true)
      allow(FileUtils).to receive(:remove_dir).with(any_args)
        .and_return(true)

      allow_any_instance_of(S3::DataEncryption).to receive(:download)
        .with(any_args).and_return(true)
      allow_any_instance_of(S3::DataEncryption).to receive(:upload)
        .with(any_args).and_return(true)
      converter.convert

      expect(document.symmetric_keys.for_user_access(nil).count).to eq(0)
    end

    it 'should raise error and should not revoke system key when image has wrong mime-type' do
      document.reload
      page.update(s3_object_key: 'image_with_exploit.jpg')
      expect(document.symmetric_keys.for_user_access(nil).count).to eq(1)

      converter = DocumentFormatConverters::ImagesToPdfConverter.new(document)
      converter.instance_variable_set(:@temp_folder_location, test_image_location)
      converter.instance_variable_set(:@temp_pdf_location, test_pdf_location)

      allow(FileUtils).to receive(:mkdir_p).with(any_args)
        .and_return(true)
      allow(FileUtils).to receive(:remove_dir).with(any_args)
        .and_return(true)

      allow_any_instance_of(S3::DataEncryption).to receive(:download)
        .with(any_args).and_return(true)
      allow_any_instance_of(S3::DataEncryption).to receive(:upload)
        .with(any_args).and_return(true)

      expect { converter.convert }.to raise_error
      expect(document.symmetric_keys.for_user_access(nil).count).to eq(1)
    end

    # FIXME: Currently we do not raise exception when trying to convert document without pages.
    # Should we add exception raise or change the spec?
    it 'should raise error and should not revoke system key when document have no pages'
=begin
    it 'should raise error and should not revoke system key when document have no pages' do
      document_without_pages = FactoryGirl.create(:document, :with_uploader_and_owner,
                                                  :with_system_symmetric_key)

      expect(document_without_pages.symmetric_keys.for_user_access(nil).count).to eq(1)
      converter = DocumentFormatConverters::ImagesToPdfConverter.new(document_without_pages)

      allow(FileUtils).to receive(:mkdir_p).with(any_args)
        .and_return(true)
      allow(FileUtils).to receive(:remove_dir).with(any_args)
        .and_return(true)

      expect { converter.convert }.to raise_error
      expect(document_without_pages.symmetric_keys.for_user_access(nil).count).to eq(1)
    end
=end
  end

end
