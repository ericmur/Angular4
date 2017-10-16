require 'google/apis/drive_v3'
require 'googleauth'

class GoogleDriveClientBuilder
  READ_ONLY_SCOPE = 'https://www.googleapis.com/auth/drive.readonly'

  def initialize(refresh_token)
    @refresh_token = refresh_token
  end

  def get_client
    client
  end

  private

  def client
    Google::Apis::DriveV3::DriveService.new.tap do |auth|
      auth.authorization = get_drive_authorizator(@refresh_token)
    end
  end

  def get_drive_authorizator(refresh_token)
    credentials = {
      client_id: ENV['GOOGLE_CLIENT_ID'],
      client_secret: ENV['GOOGLE_CLIENT_SECRET'],
      scope: READ_ONLY_SCOPE,
      refresh_token: refresh_token
    }
    Google::Auth::UserRefreshCredentials.new(credentials)
  end
end