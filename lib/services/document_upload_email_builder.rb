class DocumentUploadEmailBuilder
  def initialize(consumer, consumer_email, standard_document, business=nil)
    @consumer = consumer
    @consumer_email = consumer_email
    @standard_document = standard_document
    @business = business
  end

  def create_and_deliver
    upload_email = find_existing_upload_email
    upload_email = create_upload_email if upload_email.nil?
    if upload_email.errors.empty?
      deliver_upload_email(upload_email)
    end
    upload_email
  end

  private

  def formatted_email_address
    email_hash = SecureRandom.uuid

    [ Rails.settings['upload_email_prefix'],
      '+doc-',
      email_hash,
      '@docyt.io'
    ].join('')
  end

  def deliver_upload_email(document_upload_email)
    DocumentUploadEmailMailer.upload_email(document_upload_email).deliver_later
  end

  def create_upload_email
    DocumentUploadEmail.create({
      consumer_id: @consumer.id, 
      standard_document_id: @standard_document.id,
      email: formatted_email_address,
      consumer_email: @consumer_email,
      business: @business
    })
  end

  def find_existing_upload_email
    upload_email = DocumentUploadEmail.where(consumer_id: @consumer.id, standard_document_id: @standard_document.id).first
    if upload_email.present?
      upload_email.consumer_email = @consumer_email
      upload_email.save
    end
    upload_email
  end
end