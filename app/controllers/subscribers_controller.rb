class SubscribersController < ApplicationController
  protect_from_forgery with: :exception
  skip_before_action :doorkeeper_authorize!
  skip_before_action :confirm_phone!
  before_action :check_params

  def create
    @subscriber = Subscriber.new(subscriber_params)
    respond_to do |format|
      if @subscriber.save
        format.json { render :json => { :status => true }, :status => :ok }
      else
        format.json { render :json => { :status => false }, :status => :ok }
      end
    end
  end

  private

  def check_params
    unless params[:subscriber].present?
      respond_to do |format|
        format.json { render :json => { :status => false }, :status => :ok }
      end
    end
  end

  def subscriber_params
    params.require(:subscriber).permit(:email)
  end
end