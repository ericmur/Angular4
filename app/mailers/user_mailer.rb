class UserMailer < ApplicationMailer
  skip_before_action :add_logo_attachment!, except: [:expiring_document]

  def welcome_email(user)
    @user = user
    @subject = I18n.t('emails.subjects.welcome_email')

    delivery_options = { user_name: ENV['SES_SMTP_USERNAME'],
                         password: ENV['SES_SMTP_PASSWORD'],
                         address: ENV['SES_SMTP_ADDRESS'] }

    mail(from: email_address_for(:sid), to: @user.email, subject: @subject, content_type: 'text', delivery_method_options: delivery_options) do |format|
      format.text
    end
  end

  #We need to use SES for this and not sparkpost and sparkpost seems to have some code that clicks on the confirm url in the email and email gets confirmed as a result
  def email_confirmation(user_id, token)
    @token = token
    @user = User.find(user_id)
    @subject = I18n.t('emails.subjects.email_confirmation')

    delivery_options = { user_name: ENV['SES_SMTP_USERNAME'],
                         password: ENV['SES_SMTP_PASSWORD'],
                         address: ENV['SES_SMTP_ADDRESS'] }

    email = @user.unverified_email ? @user.unverified_email : @user.email
    mail(from: email_address_for(:noreply), to: email, subject: @subject, content_type: 'text', delivery_method_options: delivery_options) do |format|
      format.text
    end
  end

  def new_device_added(user, device)
    @user = user
    @device = device
    @subject = I18n.t('emails.subjects.new_device_added')
    @support_email = email_address_for(:support)
    mail(from: email_address_for(:noreply), to: @user.email, subject: @subject, content_type: 'text') do |format|
      format.text
    end
  end

  # Note: This require expiry/due date to be exact same date with NotifyDuration
  # notify_duration_id should non nil for NotifyDuration::EXPIRING and nil for others
  def expiring_document(user_id, document_id, field_value_id, notify_duration_id)
    @user = User.find(user_id)
    @document = Document.find(document_id)

    field_value = DocumentFieldValue.find(field_value_id)
    document_field = field_value.base_standard_document_field
    formatted_date_value = field_value.field_date_value.strftime("%m/%d/%Y")

    if notify_duration_id
      notify_duration = NotifyDuration.find(notify_duration_id)
      remaining_duration = [notify_duration.amount.to_i, notify_duration.unit.to_s.singularize.pluralize(notify_duration.amount.to_i)].join(' ')
    end

    if document_field.data_type == "due_date"
      if field_value.notification_level == NotifyDuration::EXPIRING
        if remaining_duration == "1 day"
          @notification_message = "#{@document.standard_document.name} is due tomorrow"
          @subject = "Docyt Alert - #{@document.standard_document.name} is due tomorrow"
        else
          @notification_message = "#{@document.standard_document.name} is due in #{remaining_duration} (#{formatted_date_value})"
          @subject = "Docyt Alert - #{@document.standard_document.name} is due in #{remaining_duration}"
        end
      else
        @notification_message = "#{@document.standard_document.name} is due"
        @subject = "Docyt Alert - #{@notification_message}"
      end
      @notice_type = "Due"
    else
      if field_value.notification_level == NotifyDuration::EXPIRING
        @notification_message = "#{@document.standard_document.name} is about to expire in #{remaining_duration} (#{formatted_date_value})"
        @subject = "Docyt Alert - #{@document.standard_document.name} expires in #{remaining_duration}"
      else
        @notification_message = "#{@document.standard_document.name} has expired"
        @subject = "Docyt Alert - #{@notification_message}"
      end
      @notice_type = "Expiring"
    end

    attachments.inline["error-icon.png"] = File.read("#{Rails.root}/app/assets/images/error-icon.png")

    mail(from: email_address_for(:noreply), to: @user.email, subject: @subject) do |format|
      format.html
    end
  end

end
