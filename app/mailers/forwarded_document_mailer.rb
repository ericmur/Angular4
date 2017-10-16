class ForwardedDocumentMailer < ApplicationMailer
  def unrecoverable_error_email(email_obj_id)
    @email = Email.find(email_obj_id)
    @user = @email.user
    @recipient = @user.first_name.present? ? @user.first_name.strip : "there"
    if @email.standard_document.present?
      @standard_document = @email.standard_document
      @standard_document_name = @standard_document.name
      subject = "Your attachment for #{@standard_document_name} could not be processed"
    else
      @standard_document_name = nil
      subject = "Your attachment could not be processed"
    end
    from_address = email_address_for(:notification)
    reply_to = @email.upload_email_address

    delivery_options = { user_name: ENV['SES_SMTP_USERNAME'],
                         password: ENV['SES_SMTP_PASSWORD'],
                         address: ENV['SES_SMTP_ADDRESS'] }

    mail(from: from_address, to: @user.email, reply_to: reply_to, subject: subject, delivery_method_options: delivery_options)
  end
end