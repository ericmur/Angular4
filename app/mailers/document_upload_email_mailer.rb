class DocumentUploadEmailMailer < ApplicationMailer
  skip_before_action :add_logo_attachment! # do not use inline attachment for logo, since it will also processed as attachment

  def upload_email(document_upload_email)
    consumer = document_upload_email.consumer
    @standard_document = document_upload_email.standard_document

    from_address = email_address_for(:notification)
    reply_to = document_upload_email.email
    consumer_email = document_upload_email.consumer_email
    subject = ["Upload document", @standard_document.name].join(" - ")

    delivery_options = { user_name: ENV['SES_SMTP_USERNAME'],
                         password: ENV['SES_SMTP_PASSWORD'],
                         address: ENV['SES_SMTP_ADDRESS'] }

    @logo_asset_url = get_logo_asset_url

    mail(from: from_address, reply_to: reply_to, to: consumer_email, subject: subject, delivery_method_options: delivery_options) do |format|
      format.html
    end
  end
end