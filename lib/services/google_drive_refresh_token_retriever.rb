require 'signet/oauth_2/client'

class GoogleDriveRefreshTokenRetriever
  def initialize(auth_code)
    @auth_code = auth_code

    #Seems that without this renew_refresh_token will return "certificate verify failed (Faraday::SSLError)" atleast on OS-X. Need to verify on
    #More info here: https://github.com/google/google-api-ruby-client/issues/253
    ENV['SSL_CERT_FILE'] = Gem.loaded_specs['google-api-client'].full_gem_path+'/lib/cacerts.pem'
  end

  def renew_refresh_token
    authorization = Signet::OAuth2::Client.new(
      token_credential_uri: 'https://www.googleapis.com/oauth2/v3/token',
      code: @auth_code,
      client_id: ENV['GOOGLE_CLIENT_ID'],
      client_secret: ENV['GOOGLE_CLIENT_SECRET'],
      redirect_uri: 'urn:ietf:wg:oauth:2.0:oob', 
      grant_type: 'authorization_code'
      )
    authorization.fetch_access_token!
    return authorization.refresh_token
  end
end
