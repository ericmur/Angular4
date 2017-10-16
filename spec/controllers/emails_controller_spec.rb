require 'rails_helper'

RSpec.describe EmailsController, type: :controller do
  describe 'sns_notification' do
    let(:confirmation_raw_json) { '{
      "Type" : "SubscriptionConfirmation",
      "MessageId" : "33444d09-1ca3-442f-a736-c1848ccbfcd9",
      "TopicArn" : "arn:aws:sns:us-east-1:123456789012:MyTopic",
      "Token" : "2336412f37fb687f5d51e6e241d164b14f9e81c6c9aa29262ce3fb4117fb80948fc247162d9d2b1b74c51218008d9b17aa760450f775d3dc0a5bede65011342fd6b520e5404d4e01cc29f5ba5dcc07e91498edde82b7401f7a62cc272416eed80929ae7d3c5395ceb6730fa5a41d0029d0bae9128822d25c7b6ab5b5739c9f61",
      "SubscribeURL" : "https://sns.us-east-1.amazonaws.com/?Action=ConfirmSubscription&TopicArn=arn:aws:sns:us-east-1:123456789012:MyTopic&Token=2336412f37fb687f5d51e6e241d09c805a5a57b30d712f794cc5f6a988666d92768dd60a747ba6f3beb71854e285d6ad02428b09ceece29417f1f02d609c582afbacc99c583a916b9981dd2728f4ae6fdb82efd087cc3b7849e05798d2d2785c03b0879594eeac82c01f235d0e717736"}'
    }

    let(:notification_raw_json) { '{
      "Type" : "Notification",
      "MessageId" : "3dc3259c-49c7-596c-b317-6a3a9fb3bec0",
      "TopicArn" : "arn:aws:sns:us-west-2:078530850314:email_notification",
      "Subject" : "Amazon SES Email Receipt Notification",
      "Message" : "{\"notificationType\":\"Received\",\"mail\":{\"source\":\"jbala87@gmail.com\",\"messageId\":\"6bdll8sgc6tor30admesbtb077cb1e3fijp62no1\",\"destination\":[\"hello@docyt.io\"]},\"receipt\":{\"timestamp\":\"2016-05-06T17:28:20.003Z\",\"processingTimeMillis\":590,\"recipients\":[\"hello@docyt.io\"],\"action\":{\"type\":\"S3\",\"topicArn\":\"arn:aws:sns:us-west-2:078530850314:email_notification\",\"bucketName\":\"docytio.emails\",\"objectKeyPrefix\":\"\",\"objectKey\":\"6bdll8sgc6tor30admesbtb077cb1e3fijp62no1\"}}}"
      }'
    }

    before :each do
      allow(SNSServices).to receive(:verify_authenticity).and_return(true)
    end

    it 'should confirm the endpoint on subscription confirmation type' do
      allow(SNSServices).to receive(:confirm).and_return(true)
      notification = JSON.parse(confirmation_raw_json)

      @request.env['RAW_POST_DATA'] = confirmation_raw_json
      post :sns_notification, {}
      expect(SNSServices).to have_received(:confirm).with(notification['TopicArn'], notification['Token'])
    end

    it 'should schedule a resque job to process email' do
      @request.env['RAW_POST_DATA'] = notification_raw_json
      allow(ProcessEmailFromS3Job).to receive(:perform_later)
      post :sns_notification, {}
      expect(ProcessEmailFromS3Job).to have_received(:perform_later)
    end
  end
end
