class Api::Web::V1::NotificationsQuery
  def initialize(current_advisor, params)
    @params  = params
    @current_advisor = current_advisor
  end

  def get_unread_notifications(mark_as_read = true)
    notifications = @current_advisor.notifications.where(unread: true).order(created_at: :desc).limit(10)
    mark_as_read(notifications) if mark_as_read
    notifications
  end

  private

  def mark_as_read(notifications)
    notifications.each { |notification| notification.mark_as_read }
  end
end
