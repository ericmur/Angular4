class PullEmailFromS3Service
  def initialize(message)
    @message = message
  end

  def call(&block)
    receipt = @message['receipt']
    bucket_name = receipt['action']['bucketName']
    object_key = receipt['action']['objectKey']

    object = get_object_from_s3(bucket_name, object_key)
    mail = Mail.new(object)

    email_obj = get_document_upload_email(mail)
    email_obj = get_user_upload_email(mail) if email_obj.blank?
    
    email_obj.s3_bucket_name = bucket_name
    email_obj.s3_object_key  = object_key

    if email_obj.save
      create_attachments(mail, email_obj) { |filename, mime_type, temp_file|
        block.call(email_obj, filename, mime_type, temp_file)
      }
    else
      Rails.logger.error "Unable to save email object. Couldn't create attachments."
    end
  end

  private

  def get_document_upload_email(mail)
    to_addresses = parse_email_to_addresses(mail)
    to_address = to_addresses.find { |t| DocumentUploadEmail.where(:email => t.downcase).first }
    document_upload_email = DocumentUploadEmail.where(email: to_address).first
    return nil if document_upload_email.nil?
    user = document_upload_email.consumer
    user.uploaded_emails.new(parse_email(mail).merge({ standard_document_id: document_upload_email.standard_document_id, business_id: document_upload_email.business_id }))
  end

  def get_user_upload_email(mail)
    to_addresses = parse_email_to_addresses(mail)
    to_address = to_addresses.find { |t| User.where(:upload_email => t.downcase).first }
    user = User.where(:upload_email => to_address.downcase).first
    user.uploaded_emails.new(parse_email(mail))
  end

  def get_object_from_s3(bucket_name, object_key)
    # Uncomment the following line to decrypt an encrypted message. However encryption is not working until this PR is merged: https://github.com/aws/aws-sdk-ruby/pull/1043
    # s3_client = Aws::S3::Encryption::Client.new(kms_key_id: ENV['KMS_KEY_ID'])
    s3_client = Aws::S3::Client.new
    object = s3_client.get_object(bucket: bucket_name, key: object_key).body.read
  end

  def parse_email_to_addresses(mail)
    mail.to
  end

  def parse_email(mail)
    body_text = mail.multipart? ? (mail.text_part ? mail.text_part.body.decoded : nil) : mail.body.decoded
    body_text = body_text ? body_text.force_encoding("iso8859-1").encode('utf-8') : nil
    subject = mail.subject ? mail.subject.force_encoding("iso8859-1").encode('utf-8').to_s : ""
    
    mail_params = {
      from_address: mail.from.first,
      to_addresses: mail.to.join(','),
      subject: subject,
      body_text: body_text,
      body_html: mail.html_part ? mail.html_part.body.decoded.force_encoding("iso8859-1").encode('utf-8') : nil
    }
  end

  def create_attachments(mail, email_obj, &block)
    mail.attachments.each do |attachment|
      filename = attachment.filename
      filename_extension = File.extname(filename)
      filename_without_extension = File.basename(filename, filename_extension)

      tempfile = Tempfile.new([filename_without_extension, filename_extension])
      begin
        tempfile.binmode
        tempfile << attachment.body.decoded
        tempfile.rewind
        block.call(filename, attachment.mime_type, tempfile)
      ensure
        tempfile.close
        tempfile.unlink
      end
    end
  end
end
