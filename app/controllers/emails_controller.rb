require 'sns_services'
class EmailsController < ApplicationController
  skip_before_action :doorkeeper_authorize!
  skip_before_action :confirm_phone!
  skip_before_action :confirm_device_uuid!
  
  before_filter :verify_aws_notification, only: [:sns_notification]

  def sns_notification
    notification = JSON.parse(request.raw_post)
    
    case notification['Type']
    when SNSServices::SUBSCRIPTION_CONFIRMATION_TYPE
      SNSServices.confirm(notification['TopicArn'], notification['Token'])
    when SNSServices::NOTIFICATION_TYPE
      message = JSON.parse(notification['Message'])
      unless message["mail"] && message["mail"]["messageId"] == SNSServices::AMAZON_SES_SETUP_NOTIFICATION
        ProcessEmailFromS3Job.perform_later(message)
      end
    else
      notifier = Slack::Notifier.new SLACK_WEBHOOK_URL
      notifier.ping "Unknown notification type #{notification['Type']}", channel: "#errors", username: "UploadViaEmailBot"
      Rails.logger.error "Unknown notification type #{notification['Type']}, Notification: #{notification.inspect}"
    end

    render nothing: true
  end

  private

  def verify_aws_notification
    authentic = SNSServices.verify_authenticity(request.raw_post)
    render json: {}, status: 422 and return unless authentic
  end
end
