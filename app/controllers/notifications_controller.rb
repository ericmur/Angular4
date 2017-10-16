class NotificationsController < ApplicationController
  def index
    @notifications = current_user.notifications.order(created_at: :asc)
    if params[:last_id].present?
      last_id = params[:last_id].to_i + 1
      @notifications = @notifications.where(id: last_id..Float::INFINITY)
    end
    respond_to do |format|
      format.json { render :json => @notifications }
    end
  end

  def mark_as_read
    # use find_by_id, because client may have old notification.
    @notification = current_user.notifications.find_by_id(params[:id])
    @notification.mark_as_read if @notification
    respond_to do |format|
      format.json { render :nothing => true }
    end
  end

  def destroy
    @notification = current_user.notifications.find_by_id(params[:id])
    @notification.destroy if @notification
    respond_to do |format|
      format.json { render :nothing => true }
    end
  end
end
