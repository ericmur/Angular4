class ConvertDocumentImgToPdfJob < ActiveJob::Base
  queue_as :doc_img_to_pdf_convertation

  def perform(document_id)
    document = Document.find(document_id)
    DocumentFormatConverters::ImageFileToPdfConverter.new({document: document}).convert
  end
end
