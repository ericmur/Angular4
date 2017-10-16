class Api::Web::V1::NotificationsController < Api::Web::V1::ApiController
  before_action :set_notifications, only: :index

  def index
    render status: 200, json: @notifications, each_serializer: ::Api::Web::V1::NotificationSerializer
  end

  private

  def set_notifications
    @notifications = ::Api::Web::V1::NotificationsQuery.new(current_advisor, params).get_unread_notifications
  end
end
