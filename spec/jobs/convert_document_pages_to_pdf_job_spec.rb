require 'rails_helper'
require 'spec_helper'
require 'custom_spec_helper'

RSpec.describe ConvertDocumentPagesToPdfJob do
  before do
    stub_request(:post, /.twilio.com/).to_return(status: 200)
    allow(TwilioClient).to receive_message_chain("get_instance.account.messages.create") { true }
    load_standard_documents
    load_docyt_support
  end
  let(:document) { create(:document, :with_uploader_and_owner) }

  context "#perform" do
    let(:img_to_pdf_converter) { double }

    it "should call image-to-pdf converter if document exists" do
      expect(DocumentFormatConverters::ImagesToPdfConverter).to receive(:new)
        .with(document).and_return(img_to_pdf_converter)
      expect(img_to_pdf_converter).to receive(:convert)

      ConvertDocumentPagesToPdfJob.perform(document.id)
    end

    it "should not call image-to-pdf converter if document doesn't exists" do
      expect(DocumentFormatConverters::ImagesToPdfConverter).not_to receive(:new)
      expect { ConvertDocumentPagesToPdfJob.perform(document.id+1) }
        .to raise_error(ActiveRecord::RecordNotFound)
    end
  end

  context "Resque queue solo-jobs ( ResqueSolo gem )" do
    let(:document2) { create(:document, :with_uploader_and_owner) }

    it "should only put job in the queue when the last page for the document is uploaded" do
      current_queue_size = Resque.size('img_to_pdf_convertation')
      10.times { Resque.enqueue(ConvertDocumentPagesToPdfJob, document.id) }
      new_queue_size = Resque.size('img_to_pdf_convertation')

      expect(new_queue_size).to eq(current_queue_size+1)
    end

  end

end
