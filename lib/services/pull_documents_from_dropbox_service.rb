class PullDocumentsFromDropboxService
  include Mixins::PullDocumentsUtils

  def initialize(cloud_service_path)
    @cloud_service_path = cloud_service_path
  end

  def call
    if @cloud_service_path.hash_sum != hash_by_path(@cloud_service_path.path)
      find_files(@cloud_service_path.path).each do |file_data|
        service_document = Document.find_or_initialize_by(
                                                          uploader: @cloud_service_path.consumer,
                                                          cloud_service_authorization: @cloud_service_path.cloud_service_authorization,
                                                          cloud_service_full_path: file_data['path']
                                                          )

        #For now we are going to ignore a document if it has already been pulled (even if it has been updated in the cloud). It is complicated to deal with such documents. One complication is we cannot share this document with DocytBot if it is an existing document since the key access of existing document requires logged in user.
        #if service_document.cloud_service_revision != file_data['revision']
        if service_document.new_record?
          service_document.cloud_service_revision = file_data['revision']
          service_document.original_file_name = Pathname.new(file_data['path']).basename
          service_document.source = CloudService::DROPBOX
          service_document.file_content_type = file_data['mime_type']
          service_document.cloud_service_last_modified_at = file_data['modified']
          service_document.last_modified_at = DateTime.parse(file_data['modified'])
          #service_document.state = :pending #Not needed for new_record?
          service_document.share_with_system = true
          service_document.cloud_service_path_id = @cloud_service_path.id
          service_document.save!
          service_document.start_upload!
        end
      end

      @cloud_service_path.hash_sum = hash_by_path(@cloud_service_path.path)
      @cloud_service_path.processed_at = Time.now
      @cloud_service_path.save!
    end
  end

  private

  def find_files(path)
    files_data = []

    metadata = client.metadata(path)
    if metadata && metadata.has_key?('contents')
      metadata['contents'].each do |content|
        if content['is_dir']
          files_data += find_files(content['path'])
        elsif is_allowed_content_type?(content['mime_type'])
          files_data << content
        end
      end
    end

    files_data
  end

  def hash_by_path(path)
    hash = ''

    metadata = client.metadata(path)
    hash = metadata['hash'] if metadata && metadata.has_key?('hash')

    hash
  end

  def client
    DropboxClientBuilder.new(@cloud_service_path.cloud_service_authorization.token).get_client
  end
end
