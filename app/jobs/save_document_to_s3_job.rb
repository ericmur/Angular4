class SaveDocumentToS3Job < ActiveJob::Base
  queue_as :default

  def perform(document_id)
    document = Document.find_by_id(document_id)
    cloud_service_name = document.cloud_service_authorization.cloud_service.name
    temp_file_location = "tmp/tmp_downloads/#{document.id}"

    case cloud_service_name
    when CloudService::DROPBOX
      file = GetFileFromDropboxService.new(document, temp_file_location).call
    when CloudService::GOOGLE_DRIVE
      file = GetFileFromGoogleDriveService.new(document, temp_file_location).call
    end

    S3DocumentUploaderService.new(document, file).call
    PerformAutocategorizationJob.perform_later(document.id)
  end
end