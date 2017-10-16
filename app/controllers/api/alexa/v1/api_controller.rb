class Api::Alexa::V1::ApiController < ActionController::Base
  protect_from_forgery with: :null_session
  before_action :doorkeeper_authorize!
  before_action :set_docyt_bot_app_type
  before_action :confirm_device_uuid!
  
  protected
  def set_docyt_bot_app_type
    Rails.set_user_oauth_token(doorkeeper_token.token)
    Rails.set_app_type(User::DOCYT_BOT_APP)
  end

  def confirm_device_uuid!
    if current_user and current_user.confirmed_devices.where(:device_uuid => params[:device_uuid]).first.nil?
      respond_to do |format|
        format.json { render :json => { :errors => ["Device not authorized to use the application"] }, status: :forbidden }
      end
    end
  end
  
  def current_user
    if doorkeeper_token
      @current_user ||= User.where(:id => doorkeeper_token.resource_owner_id).first
    else
      nil
    end
  end
end
