class ConvertDocumentPdfToImgJob < ActiveJob::Base
  queue_as :pdf_to_img_convertation

  def perform(document_id)
    document = Document.find(document_id)

    raise "Document #{document.id} doesn't contain attached .pdf document" if document.final_file_key.blank?
    DocumentFormatConverters::PdfToImagesConverter.new(document).convert
  end
end
