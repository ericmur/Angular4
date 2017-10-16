require 'rails_helper'
require 'custom_spec_helper'
require 's3'

RSpec.describe DocumentFormatConverters::MicrosoftFileToPdfConverter do
  before do
    Rails.set_app_type(User::WEB_APP)
    load_standard_documents
    load_docyt_support

    allow_any_instance_of(SymmetricKey).to receive(:decrypt_key).and_return(Faker::Code.ean)
    allow_any_instance_of(SymmetricKey).to receive(:decrypt_iv).and_return(Faker::Code.ean)
    allow_any_instance_of(S3::DataEncryption).to receive(:download).and_return(true)
    allow_any_instance_of(converter).to receive(:create_and_upload_pages).and_return(true)
    allow_any_instance_of(Document).to receive(:s3_object_exists?).and_return(true)
    allow(File).to receive(:delete).and_return(true)
    create(:cloud_service_authorization)
  end

  let!(:advisor)   { create(:advisor) }

  let!(:converter) { DocumentFormatConverters::MicrosoftFileToPdfConverter }

  let!(:test_pdf_location)  { File.new('./spec/data/test_file.pdf') }

  let!(:cloud_service_authorization) { CloudServiceAuthorization.first }

  let!(:document_ms_doc) {
    create(:document, :specific_extension,
      source: 'WebChat',
      uploader: advisor,
      file_content_type:  "application/msword",
      original_file_name: "#{Faker::Lorem.word}.doc",
      cloud_service_authorization: cloud_service_authorization
    )
  }

  let!(:document_ms_xls) {
    create(:document, :specific_extension,
      source: 'WebChat',
      uploader: advisor,
      file_content_type:  "application/vnd.ms-excel",
      original_file_name: "#{Faker::Lorem.word}.xml",
      cloud_service_authorization: cloud_service_authorization
    )
  }

  let!(:document_ms_ppt)  {
    create(:document, :specific_extension,
      source: 'WebChat',
      uploader: advisor,
      file_content_type:  "application/vnd.ms-powerpoint",
      original_file_name: "#{Faker::Lorem.word}.ppt",
      cloud_service_authorization: cloud_service_authorization
    )
  }

  let!(:document_ms_docx) {
    create(:document, :specific_extension,
      source: 'WebChat',
      uploader: advisor,
      file_content_type:  "application/vnd.openxmlformats-officedocument.wordprocessingml.document",
      original_file_name: "#{Faker::Lorem.word}.docx",
      cloud_service_authorization: cloud_service_authorization
    )
  }

  context '#convert' do
    it 'should convert old microsoft word document to pdf' do
      allow(File).to receive(:new).and_return(test_pdf_location)
      document_ms_doc.share_with(by_user_id: advisor.id, with_user_id: nil)

      expect(document_ms_doc.original_file_name).to eq(document_ms_doc.final_file_key)

      converter.new({document: document_ms_doc}).convert

      document_ms_doc.reload

      expect(document_ms_doc.original_file_name).to_not eq(document_ms_doc.final_file_key)
      expect(document_ms_doc.final_file_key).to eq(File.basename(test_pdf_location))
    end

    it 'should convert microsoft excel document to pdf' do
      allow(File).to receive(:new).and_return(test_pdf_location)
      document_ms_xls.share_with(by_user_id: advisor.id, with_user_id: nil)

      expect(document_ms_xls.original_file_name).to eq(document_ms_xls.final_file_key)

      converter.new({document: document_ms_xls}).convert

      document_ms_xls.reload

      expect(document_ms_xls.original_file_name).to_not eq(document_ms_xls.final_file_key)
      expect(document_ms_xls.final_file_key).to eq(File.basename(test_pdf_location))
    end

    it 'should convert new microsoft word document to pdf' do
      allow(File).to receive(:new).and_return(test_pdf_location)
      document_ms_docx.share_with(by_user_id: advisor.id, with_user_id: nil)

      expect(document_ms_docx.original_file_name).to eq(document_ms_docx.final_file_key)

      converter.new({document: document_ms_docx}).convert

      document_ms_docx.reload

      expect(document_ms_docx.original_file_name).to_not eq(document_ms_docx.final_file_key)
      expect(document_ms_docx.final_file_key).to eq(File.basename(test_pdf_location))
    end

    it 'should convert microsoft power point document to pdf' do
      allow(File).to receive(:new).and_return(test_pdf_location)
      document_ms_ppt.share_with(by_user_id: advisor.id, with_user_id: nil)

      expect(document_ms_ppt.original_file_name).to eq(document_ms_ppt.final_file_key)

      converter.new({document: document_ms_ppt}).convert

      document_ms_ppt.reload

      expect(document_ms_ppt.original_file_name).to_not eq(document_ms_ppt.final_file_key)
      expect(document_ms_ppt.final_file_key).to eq(File.basename(test_pdf_location))
    end
  end
end
