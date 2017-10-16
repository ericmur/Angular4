class OauthSessionsController < ApplicationController
  skip_before_action :doorkeeper_authorize!, :except => [:destroy]
  skip_before_action :confirm_phone!, :except => [:destroy]
  skip_before_action :confirm_device_uuid!, :except => [:destroy]

  def new
    @redirect_uri = params[:redirect_uri]
    @state = params[:state]
    @client_id = params[:client_id]
    
    render :layout => false
  end
  
  def create
    phone = params[:phone]
    pin = params[:pin]
    redirect_uri = params[:redirect_uri]
    state = params[:state]
    client_id = params[:client_id]

    user = User.find_by(phone_normalized: PhonyRails.normalize_number(phone, :country_code => User::PHONE_COUNTRY_CODE))
    if user
      if user.valid_pin? pin.try(:strip)
        client = Doorkeeper::Application.find_by_name(client_id)
        access_token = Doorkeeper::AccessToken.find_or_create_for(client, user.id, nil, nil, nil)
        user.update_oauth_encrypted_private_key_using_pin(pin.try(:strip), access_token.token)
        UserStatisticService.new(user).set_last_logged_in_alexa
        redirect_uri_with_params = prepare_redirect_uri(redirect_uri, { :state => state, :access_token => access_token.token, :token_type => "Bearer" })
        redirect_to(redirect_uri_with_params.to_s)
      else
        flash[:notice] = "Invalid password."
        render :action => 'new', :layout => false
      end
    else
      flash[:notice] = "No user found with that phone number."
      render :action => 'new', :layout => false
    end
  end

  def destroy
    #####TODO: https://github.com/doorkeeper-gem/doorkeeper/issues/500
    current_advisor.authentication_token = nil
    current_advisor.auth_token_private_key = nil
    current_advisor.save!
    render status: 204, json: nil
  end

  private
  def prepare_redirect_uri(uri, params)
    redirect_uri = URI.parse(uri)
    new_params = URI.encode_www_form(params.to_a)
    redirect_uri.fragment = new_params
    redirect_uri
  end
end
