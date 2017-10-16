require 'sns_services'

class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :null_session
  before_action :doorkeeper_authorize!
  before_action :confirm_phone!, :unless => :demo_account?
  before_action :confirm_device_uuid!, :unless => :demo_account?
  before_action :get_app_version

  include ApplicationHelper
  serialization_scope :view_context

  rescue_from ActiveRecord::RecordNotFound, with: lambda{ |e| request.format.json? ? record_not_found : raise(e) }

  protected

  def get_app_version
    Rails.set_mobile_app_version(params[:app_version])
  end
  
  def with_sns_notification(botname)
    notification = JSON.parse(request.raw_post)
    case notification['Type']
    when SNSServices::SUBSCRIPTION_CONFIRMATION_TYPE
      SNSServices.confirm(notification['TopicArn'], notification['Token'])
    when SNSServices::NOTIFICATION_TYPE
      message = JSON.parse(notification['Message'])
      yield(message)
    else
      notifier = Slack::Notifier.new SLACK_WEBHOOK_URL
      notifier.ping "Unknown notification type #{notification['Type']}", channel: "#errors", username: botname
      Rails.logger.error "Unknown notification type #{notification['Type']}, Notification: #{notification.inspect}"
    end
  end

  def verify_aws_notification
    authentic = SNSServices.verify_authenticity(request.raw_post)
    render json: {}, status: 422 and return unless authentic
  end

  def demo_account?
    current_user and ['docytdemo@gmail.com', 'aibek@docyt.com', 'the.eolithic@gmail.com', 'ashishp@gmail.com'].include?(current_user.email)
  end
  
  def current_user
    if doorkeeper_token
      @current_user ||= User.where(:id => doorkeeper_token.resource_owner_id).first
    else
      nil
    end
  end

  def confirm_phone!
    unless current_user && current_user.confirmed_phone?
      respond_to do |format|
        format.json { render :json => { :errors => ["Confirmed phone number is required to use the application"] }, status: :forbidden }
      end
    end
  end

  def confirm_device_uuid!
    if current_user and current_user.confirmed_devices.where(:device_uuid => params[:device_uuid]).first.nil?
      respond_to do |format|
        format.json { render :json => { :errors => ["Device not authorized to use the application"] }, status: :forbidden }
      end
    end
  end

  def load_user_password_hash
    if params[:password_hash].nil?
      respond_to do |format|
        format.json { render :json => { :errors => ["Password hash required to access private key"] }, :status => :not_acceptable }
      end
    else
      Rails.set_user_password_hash(params[:password_hash])
      Rails.set_app_type(User::MOBILE_APP)
    end
  end

  def record_not_found
    respond_to do |format|
      format.json { render :json => { :errors => ["Record not found."]}, :status => :not_found }
    end
  end

  helper_method :current_user
end
