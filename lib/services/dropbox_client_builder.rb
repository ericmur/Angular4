class DropboxClientBuilder
  def initialize(auth_token)
    @auth_token = auth_token
  end

  def get_client
    client
  end

  private

  def client
    ::DropboxClient.new(@auth_token)
  end
end
