class AdminMailer < ApplicationMailer
  skip_before_action :add_logo_attachment!

  def download_exhausted(object_id, object_klass_name)
    klass = object_klass_name.constantize
    @object_klass_name = object_klass_name
    @object = klass.where(:id => object_id).first
    @subject = "(#{Rails.env}) - #{object_klass_name} download exhausted!"

    mail(from: email_address_for(:noreply),
          to: ['sugam@docyt.com', 'tedi@docyt.com'], 
          subject: @subject, 
          content_type: 'text') do |format|
      format.text
    end
  end

  def users_and_pages_statistics(range, users_count, pages_count, total_pages_count, documents_count, total_documents_count, messages_count, start_date, end_date=nil)
    @range = range
    @users_count = users_count
    @pages_count = pages_count
    @total_pages_count = total_pages_count
    @documents_count = documents_count
    @total_documents_count = total_documents_count
    @start_date = start_date
    @end_date = end_date
    @messages_count = messages_count

    if @range == "daily"
      @subject = "(#{Rails.env}) #{@range.titleize} statistics (#{@start_date})"
    else
      @subject = "(#{Rails.env}) #{@range.titleize} statistics (#{@start_date} to #{@end_date})"
    end
    mail(from: email_address_for(:noreply),
          to: ['sugam@docyt.com', 'sid@docyt.com'],
          subject: @subject, 
          content_type: 'text') do |format|
      format.text
    end
  end
end
