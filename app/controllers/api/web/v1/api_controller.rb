class Api::Web::V1::ApiController < ActionController::Base
  respond_to :json
  before_action :check_authentication
  before_action :set_web_app_type
  serialization_scope :current_advisor # this is used to pass advisor into serializer

  private

  def set_web_app_type
    Rails.set_app_type(User::WEB_APP)
  end

  def check_authentication
    render json: { error_message: 'Invalid authentication_token.' }, status: 401 if current_advisor.nil?
  end

  def current_advisor
    if auth_token.present?
      @current_advisor ||= User.find_by(authentication_token: auth_token)
    end
  end

  def auth_token
    request.headers['X-User-Token']
  end
end
