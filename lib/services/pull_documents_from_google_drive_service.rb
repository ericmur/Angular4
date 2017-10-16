require 'digest/md5'

class PullDocumentsFromGoogleDriveService
  include Mixins::PullDocumentsUtils

  PAGE_SIZE = 1000

  def initialize(cloud_service_path)
    @cloud_service_path = cloud_service_path
    @folders = []
    @files = []
    @data_for_hash_calculation = []
    @drive = get_drive_client

    #Seems that without this renew_refresh_token will return "certificate verify failed (Faraday::SSLError)" atleast on OS-X. Need to verify on
    #More info here: https://github.com/google/google-api-ruby-client/issues/253
    ENV['SSL_CERT_FILE'] = Gem.loaded_specs['google-api-client'].full_gem_path+'/lib/cacerts.pem'
  end

  def call
    hsh = hash_by_path(@cloud_service_path.path)
    if @cloud_service_path.hash_sum != hsh
      find_files(@cloud_service_path.path)

      @files.each do |file_data|
        service_document = Document.find_or_initialize_by(
                                                          uploader: @cloud_service_path.consumer,
                                                          cloud_service_authorization: @cloud_service_path.cloud_service_authorization,
                                                          cloud_service_full_path: file_data.id
                                                          )
        #For now we are going to ignore a document if it has already been pulled (even if it has been updated in the cloud)
        #if service_document.cloud_service_revision != file_data.version
        if service_document.new_record?
          service_document.cloud_service_revision = file_data.version
          service_document.source = CloudService::GOOGLE_DRIVE
          service_document.original_file_name = file_data.name
          service_document.file_content_type = file_data.mime_type
          service_document.cloud_service_last_modified_at = file_data.modified_time.to_s
          service_document.last_modified_at = file_data.modified_time
          #service_document.state = :pending #Not needed for new_record?
          service_document.share_with_system = true
          service_document.cloud_service_path_id = @cloud_service_path.id
          service_document.save!
          service_document.start_upload!
        end
      end
      @cloud_service_path.hash_sum = hsh
      @cloud_service_path.processed_at = Time.now
      @cloud_service_path.save!
    end
  end

  private

  def find_files(path)
    page_token = nil
    query = build_query_string(path)

    begin
      result = @drive.list_files(q: query,
                                page_size: PAGE_SIZE,
                                page_token: page_token,
                                fields: 'files(id, name, mimeType, modifiedTime, version), next_page_token')
      result.files.each do |file|
        if file.mime_type == 'application/vnd.google-apps.folder'
          find_files(file.id)
        elsif is_allowed_content_type?(file.mime_type)
          @files << file
        end
      end

      if result.next_page_token
        page_token = result.next_page_token
      else
        page_token = nil
      end
    end while !page_token.nil?
  end

  def hash_by_path(path)
    page_token = nil
    query = build_query_string(path)
    begin
      result = @drive.list_files(q: query,
                                 order_by: 'modifiedTime',
                                 page_size: PAGE_SIZE,
                                 page_token: page_token,
                                 fields: 'files(id, modifiedTime, mime_type), next_page_token'
                                )
      result.files.each do |file|
        if file.mime_type == 'application/vnd.google-apps.folder'
          @data_for_hash_calculation << file.modified_time
          hash_by_path(file.id)
        else
          @data_for_hash_calculation << file.modified_time
        end
      end

      if result.next_page_token
        page_token = result.next_page_token
      else
        page_token = nil
      end
    end while !page_token.nil?
    Digest::MD5.hexdigest(@data_for_hash_calculation.to_json)
  end

  def build_query_string(path)
    "
    '#{path}' in parents
    "
  end

  def get_drive_client
    GoogleDriveClientBuilder.new(@cloud_service_path.cloud_service_authorization.token).get_client
  end
end
