class GetFileFromDropboxService
  def initialize(document, temp_file_location)
    @document = document
    @cloud_service_auth_token = @document.cloud_service_authorization.token
    @temp_file_location = temp_file_location
  end

  def call
    FileUtils::mkdir_p(@temp_file_location)
    file = File.new("#{@temp_file_location}/#{@document.original_file_name}", 'wb')
    file << client.get_file(@document.cloud_service_full_path)
    file.close
    file
  end

  private

  def client
    DropboxClientBuilder.new(@cloud_service_auth_token).get_client
  end
end
