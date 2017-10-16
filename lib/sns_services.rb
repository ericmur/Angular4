class SNSServices
  SUBSCRIPTION_CONFIRMATION_TYPE = 'SubscriptionConfirmation'
  NOTIFICATION_TYPE = 'Notification'
  AMAZON_SES_SETUP_NOTIFICATION = "AMAZON_SES_SETUP_NOTIFICATION"

  def self.confirm(arn, token)
    sns_client = Aws::SNS::Client.new
    sns_client.confirm_subscription({ topic_arn: arn, token: token })
  end

  def self.verify_authenticity(message_body)
    return false if message_body.blank?
    verifier = Aws::SNS::MessageVerifier.new
    verifier.authentic?(message_body)
  end
end
