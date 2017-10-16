require 'rails_helper'
require 'sns_services'
require 'spec_helper'
require 'custom_spec_helper'

RSpec.describe ProcessEmailFromS3Job do
  describe 'process email in background job' do
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
      "Message" : "{\"notificationType\":\"Received\",\"mail\":{\"source\":\"jbala87@gmail.com\",\"messageId\":\"6bdll8sgc6tor30admesbtb077cb1e3fijp62no1\",\"destination\":[\"hello@docyt.io\"]},\"receipt\":{\"timestamp\":\"2016-05-06T17:28:20.003Z\",\"processingTimeMillis\":590,\"recipients\":[\"hello@docyt.io\"],\"action\":{\"type\":\"S3\",\"topicArn\":\"arn:aws:sns:us-west-2:078530850314:email_notification\",\"bucketName\":\"docyt-test-emails\",\"objectKeyPrefix\":\"\",\"objectKey\":\"6bdll8sgc6tor30admesbtb077cb1e3fijp62no1\"}}}"
      }'
    }

    before :each do
      allow(SNSServices).to receive(:verify_authenticity).and_return(true)
      load_standard_documents
      load_docyt_support
    end

    it 'should create an email on notification type. Without attachments' do
      email_path = Rails.root.join('spec', 'data', '88eoqb00c97o5758bb65asdf77cb1e1hm3846v81')
      email_data = File.read(email_path)
      FactoryGirl.create(:user, :upload_email => "hello@docyt.io")
      allow_any_instance_of(PullEmailFromS3Service).to receive(:get_object_from_s3).and_return(email_data)
      allow_any_instance_of(S3DocumentUploaderService).to receive(:call)
      ProcessEmailFromS3Job.new.perform(JSON.parse(JSON.parse(notification_raw_json)["Message"]))

      expect(Email.count).to eq(1)
      expect(Document.count).to eq(0)
      email = Email.last

      expect(email.s3_bucket_name).not_to eq(nil)
      expect(email.s3_object_key).not_to eq(nil)

      expect(email.from_address).to eq 'jbala87@gmail.com'
      expect(email.to_addresses).to eq 'hello@docyt.io'
      expect(email.subject).to eq 'Hello!'
      expect(email.body_text).to eq "Bye Bye\n"
    end

    it 'should create an email on notification type. With attachments' do
      email_path = Rails.root.join('spec', 'data', '2epk2qek6ghls3apojnnb7744v3at9h6dbv6qko1')
      email_data = File.read(email_path)
      FactoryGirl.create(:user, :upload_email => "hello@docyt.io")
      
      allow_any_instance_of(PullEmailFromS3Service).to receive(:get_object_from_s3).and_return(email_data)
      allow_any_instance_of(S3DocumentUploaderService).to receive(:call)
      ProcessEmailFromS3Job.new.perform(JSON.parse(JSON.parse(notification_raw_json)["Message"]))
      
      expect(Email.count).to eq(1)
      expect(Document.count).to eq(1)
      
      email = Email.last
      expect(email.documents.count).to eq(1)
    end
  end
end
