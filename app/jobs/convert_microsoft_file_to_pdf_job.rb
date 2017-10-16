class ConvertMicrosoftFileToPdfJob < ActiveJob::Base
  queue_as :microsoft_file_to_pdf_convertation

  def perform(document_id)
    document = Document.find(document_id)
    DocumentFormatConverters::MicrosoftFileToPdfConverter.new({document: document}).convert
  end
end
