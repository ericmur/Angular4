module DocumentFormatConverters
  class FlattenPdfConverter < BaseDocumentConverter
    def initialize(document)
      @document = document
    end

    def convert
      temp_file = download_document_file
      @temp_file_path = temp_file.path
      pdf_service = FlattenPdfService.new(@temp_file_path)

      if pdf_service.fillable?
        pdf_service.flatten
        temp_file = File.new(@temp_file_path, 'r')
        upload_to_s3(temp_file.path, @document.original_file_key)
      end

      @document.complete_convertation!
    ensure
      File.delete(@temp_file_path)
    end
  end
end