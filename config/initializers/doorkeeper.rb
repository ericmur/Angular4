Doorkeeper.configure do
  # Change the ORM that doorkeeper will use.
  # Currently supported options are :active_record, :mongoid2, :mongoid3, :mongo_mapper
  orm :active_record

  # This block will be called to check whether the resource owner is authenticated or not.
  resource_owner_authenticator do
    # fail "Please configure doorkeeper resource_owner_authenticator block located in #{__FILE__}"
    # Put your resource owner authentication logic here.
    # Example implementation:
    # User.find_by_id(session[:user_id]) || redirect_to(new_user_session_url)
    token = Doorkeeper.authenticate(request)
    if token && token.accessible?
      User.find_by_id(token.resource_owner_id)
    else
      redirect_to(new_oauth_session_url(:redirect_uri => params[:redirect_uri], :state => params[:state], :client_id => params[:client_id]))
    end
  end

  resource_owner_from_credentials do |routes|
    if params[:pin]
      #This if block has check for params[:email] for backward compatibility with app versions < 1.0.5 when login had email/pin, instead of phone/pin. The day when everyone is above 1.0.5 this block of code can be removed and =begin/=end below could be uncommented.

      if params[:email]
        u = User.where(:email => params[:email].try(:strip)).first
      else
        u = User.where(:phone_normalized => PhonyRails.normalize_number(params[:phone].try(:strip), :country_code => User::PHONE_COUNTRY_CODE)).first
      end

      if u && u.valid_pin?(params[:pin].try(:strip))
        UserStatisticService.new(u).set_last_logged_in_iphone_app if params[:device_uuid].present?
        u
      else
        nil
      end

=begin      
      u = Consumer.where(:phone_normalized => PhonyRails.normalize_number(params[:phone].try(:strip), :country_code => User::PHONE_COUNTRY_CODE)).first
      u and u.valid_pin?(params[:pin].try(:strip)) ? u : nil
=end
    else
      if params[:email]
        u = User.where(:email => params[:email].try(:strip)).first
      else
        u = User.where(:phone_normalized => PhonyRails.normalize_number(params[:phone].try(:strip), :country_code => User::PHONE_COUNTRY_CODE)).first
      end
      if u.valid_forgot_pin_token?(params[:forgot_pin_token].try(:strip))
        u.confirm_forgot_pin_token
        u
      else
        nil
      end
    end
  end

  # If you want to restrict access to the web interface for adding oauth authorized applications, you need to declare the block below.
  # admin_authenticator do
  #   # Put your admin authentication logic here.
  #   # Example implementation:
  #   Admin.find_by_id(session[:admin_id]) || redirect_to(new_admin_session_url)
  # end

  # Authorization Code expiration time (default 10 minutes).
  # authorization_code_expires_in 10.minutes

  # Access token expiration time (default 2 hours).
  # If you want to disable expiration, set this to nil.
  access_token_expires_in 8.hours

  # Reuse access token for the same resource owner within an application (disabled by default)
  # Rationale: https://github.com/doorkeeper-gem/doorkeeper/issues/383
  # reuse_access_token

  # Issue access tokens with refresh token (disabled by default)
  use_refresh_token

  # Provide support for an owner to be assigned to each registered application (disabled by default)
  # Optional parameter :confirmation => true (default false) if you want to enforce ownership of
  # a registered application
  # Note: you must also run the rails g doorkeeper:application_owner generator to provide the necessary support
  # enable_application_owner :confirmation => false

  # Define access token scopes for your provider
  # For more information go to
  # https://github.com/doorkeeper-gem/doorkeeper/wiki/Using-Scopes
  # default_scopes  :public
  # optional_scopes :write, :update

  # Change the way client credentials are retrieved from the request object.
  # By default it retrieves first from the `HTTP_AUTHORIZATION` header, then
  # falls back to the `:client_id` and `:client_secret` params from the `params` object.
  # Check out the wiki for more information on customization
  # client_credentials :from_basic, :from_params

  # Change the way access token is authenticated from the request object.
  # By default it retrieves first from the `HTTP_AUTHORIZATION` header, then
  # falls back to the `:access_token` or `:bearer_token` params from the `params` object.
  # Check out the wiki for more information on customization
  # access_token_methods :from_bearer_authorization, :from_access_token_param, :from_bearer_param

  # Change the native redirect uri for client apps
  # When clients register with the following redirect uri, they won't be redirected to any server and the authorization code will be displayed within the provider
  # The value can be any string. Use nil to disable this feature. When disabled, clients must provide a valid URL
  # (Similar behaviour: https://developers.google.com/accounts/docs/OAuth2InstalledApp#choosingredirecturi)
  #
  # native_redirect_uri 'urn:ietf:wg:oauth:2.0:oob'

  # Specify what grant flows are enabled in array of Strings. The valid
  # strings and the flows they enable are:
  #
  # "authorization_code" => Authorization Code Grant Flow
  # "implicit"           => Implicit Grant Flow
  # "password"           => Resource Owner Password Credentials Grant Flow
  # "client_credentials" => Client Credentials Grant Flow
  #
  # If not specified, Doorkeeper enables all the four grant flows.
  #
  # grant_flows %w(authorization_code implicit password client_credentials)

  # Under some circumstances you might want to have applications auto-approved,
  # so that the user skips the authorization step.
  # For example if dealing with a trusted application.
  skip_authorization do |resource_owner, client|
    whitelisted_apps = []
    whitelisted_apps.include? client.application.uid
  #   client.superapp? or resource_owner.admin?
  end

  # WWW-Authenticate Realm (default "Doorkeeper").
  # realm "Doorkeeper"

  # Allow dynamic query parameters (disabled by default)
  # Some applications require dynamic query parameters on their request_uri
  # set to true if you want this to be allowed
  # wildcard_redirect_uri false
end

Doorkeeper.configuration.token_grant_types << "password"
Doorkeeper.configuration.token_grant_types << "implicit" 
