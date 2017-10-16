require 'rails_helper'
require 'custom_spec_helper'
require 's3'

RSpec.describe DocumentFormatConverters::ImageFileToPdfConverter do
  before do
    Rails.set_app_type(User::WEB_APP)
    load_standard_documents
    load_docyt_support

    allow_any_instance_of(SymmetricKey).to receive(:decrypt_key).and_return(Faker::Code.ean)
    allow_any_instance_of(SymmetricKey).to receive(:decrypt_iv).and_return(Faker::Code.ean)
    allow_any_instance_of(S3::DataEncryption).to receive(:download).and_return(true)
    allow_any_instance_of(S3::DataEncryption).to receive(:upload).and_return(true)
    allow_any_instance_of(converter).to receive(:create_and_upload_pages).and_return(true)
    allow_any_instance_of(Document).to receive(:s3_object_exists?).and_return(true)
    allow(File).to receive(:delete).and_return(true)
    create(:cloud_service_authorization)
  end

  let!(:advisor)   { create(:advisor) }

  let!(:converter) { DocumentFormatConverters::ImageFileToPdfConverter }

  let!(:test_pdf_location)  { File.new('./spec/data/test_file.pdf') }

  let!(:cloud_service_authorization) { CloudServiceAuthorization.first }

  let!(:document_jpg) {
    create(:document, :specific_extension,
      source: 'WebChat',
      uploader: advisor,
      file_content_type:  "image/jpeg",
      original_file_name: "#{Faker::Lorem.word}.jpg",
      cloud_service_authorization: cloud_service_authorization
    )
  }

  let!(:document_png) {
    create(:document, :specific_extension,
      source: 'WebChat',
      uploader: advisor,
      file_content_type:  "image/png",
      original_file_name: "#{Faker::Lorem.word}.png",
      cloud_service_authorization: cloud_service_authorization
    )
  }

  let!(:document_gif) {
    create(:document, :specific_extension,
      source: 'WebChat',
      uploader: advisor,
      file_content_type:  "image/gif",
      original_file_name: "#{Faker::Lorem.word}.gif",
      cloud_service_authorization: cloud_service_authorization
    )
  }

  context '#convert' do
    it 'should convert jpeg document to pdf' do
      allow(File).to receive(:new).and_return(test_pdf_location)
      document_jpg.share_with(by_user_id: advisor.id, with_user_id: nil)

      expect(document_jpg.original_file_name).to eq(document_jpg.final_file_key)

      converter.new({document: document_jpg}).convert

      document_jpg.reload

      expect(document_jpg.original_file_name).to_not eq(document_jpg.final_file_key)
      expect(document_jpg.final_file_key).to eq(File.basename(test_pdf_location))
    end

    it 'should convert png document to pdf' do
      allow(File).to receive(:new).and_return(test_pdf_location)
      document_png.share_with(by_user_id: advisor.id, with_user_id: nil)

      expect(document_png.original_file_name).to eq(document_png.final_file_key)

      converter.new({document: document_png}).convert

      document_png.reload

      expect(document_png.original_file_name).to_not eq(document_png.final_file_key)
      expect(document_png.final_file_key).to eq(File.basename(test_pdf_location))
    end

    it 'should convert gif document to pdf' do
      allow(File).to receive(:new).and_return(test_pdf_location)
      document_gif.share_with(by_user_id: advisor.id, with_user_id: nil)

      expect(document_gif.original_file_name).to eq(document_gif.final_file_key)

      converter.new({document: document_gif}).convert

      document_gif.reload

      expect(document_gif.original_file_name).to_not eq(document_gif.final_file_key)
      expect(document_gif.final_file_key).to eq(File.basename(test_pdf_location))
    end
  end

end
