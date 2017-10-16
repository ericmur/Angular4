class DocumentAccessRequestsController < ApplicationController
  before_action :load_user_password_hash, :only => [:approve_request]
  
  def index
    consumer = User.find(params[:user_id])
    access_requests = DocumentAccessRequest.created_by(consumer.id).uploaded_by(current_user.id)
    respond_to do |format|
      format.json { render json: access_requests }
    end
  end

  def request_access
    access_request = DocumentAccessRequest.find(params[:request_id])
    access_request.send_request_notification
    respond_to do |format|
      format.json { render json: { success: true } }
    end
  end

  def approve_request
    consumer = User.find(params[:user_id])
    processed_requests_count = DocumentAccessRequest.process_access_request_for_user(current_user, consumer)
    respond_to do |format|
      format.json { render json: { success: true } }
    end
  end
end
