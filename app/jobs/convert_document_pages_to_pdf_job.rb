class ConvertDocumentPagesToPdfJob
  include Resque::Plugins::UniqueJob
  @queue = :img_to_pdf_convertation

  def self.perform(document_id)
    document = Document.find(document_id)

    DocumentFormatConverters::ImagesToPdfConverter.new(document).convert
  end
end
