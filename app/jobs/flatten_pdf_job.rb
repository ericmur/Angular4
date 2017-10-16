class FlattenPdfJob < ActiveJob::Base
  queue_as :flatten_pdf

  def perform(document_id)
    document = Document.find(document_id)
    DocumentFormatConverters::FlattenPdfConverter.new(document).convert
  end
end