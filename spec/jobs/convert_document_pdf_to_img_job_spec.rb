require 'rails_helper'
require 'spec_helper'
require 'custom_spec_helper'

RSpec.describe ConvertDocumentPdfToImgJob do
  before do
    stub_request(:post, /.twilio.com/).to_return(status: 200)
    allow(TwilioClient).to receive_message_chain("get_instance.account.messages.create") { true }
    load_standard_documents
    load_docyt_support
  end
  let(:document) { create(:document, :with_uploader_and_owner) }

  context "#perform" do
    let(:pdf_to_img_converter) { double }

    it "should call pdf-to-image converter if document exists" do
      expect(DocumentFormatConverters::PdfToImagesConverter).to receive(:new)
        .with(document).and_return(pdf_to_img_converter)
      expect(pdf_to_img_converter).to receive(:convert)

      ConvertDocumentPdfToImgJob.new.perform(document.id)
    end

    it "should not call pdf-to-image converter if document doesn't exists" do
      expect(DocumentFormatConverters::PdfToImagesConverter).not_to receive(:new)
      expect { ConvertDocumentPdfToImgJob.new.perform(document.id+1) }
        .to raise_error(ActiveRecord::RecordNotFound)
    end

    it "should not call pdf-to-image converter and raise exception if document have no final_file_key" do
      document.update(final_file_key: nil)

      expect(DocumentFormatConverters::PdfToImagesConverter).not_to receive(:new)
      expect { ConvertDocumentPdfToImgJob.perform(document.id) }.to raise_error
    end
  end

end
