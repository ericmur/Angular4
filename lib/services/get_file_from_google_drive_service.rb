class GetFileFromGoogleDriveService
  def initialize(document, temp_file_location)
    @document = document
    @cloud_service_auth_token = @document.cloud_service_authorization.token
    @temp_file_location = temp_file_location
    
    #Seems that without this renew_refresh_token will return "certificate verify failed (Faraday::SSLError)" atleast on OS-X. Need to verify on
    #More info here: https://github.com/google/google-api-ruby-client/issues/253
    ENV['SSL_CERT_FILE'] = Gem.loaded_specs['google-api-client'].full_gem_path+'/lib/cacerts.pem'
  end

  def call
    FileUtils::mkdir_p(@temp_file_location)
    client.get_file(@document.cloud_service_full_path, download_dest: "#{@temp_file_location}/#{@document.original_file_name}")
    file = File.open("#{@temp_file_location}/#{@document.original_file_name}")
    file.close
    file
  end

  private

  def client
    GoogleDriveClientBuilder.new(@cloud_service_auth_token).get_client
  end

end
