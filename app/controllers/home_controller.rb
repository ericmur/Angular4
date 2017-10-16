class HomeController < ApplicationController
  include ApplicationHelper
  protect_from_forgery with: :exception
  skip_before_action :doorkeeper_authorize!
  skip_before_action :confirm_phone!

  def index
    redirect_to '/web/', status: 301
  end

  def privacy
    redirect_to '/web/privacy', status: 301
  end

  def terms
    redirect_to '/web/terms', status: 301
  end

  def features
    redirect_to '/web/features', status: 301
  end

  def security
    redirect_to '/web/security', status: 301
  end

  def about
    redirect_to '/web/about', status: 301
  end

  def pricing
    redirect_to '/web/pricing', status: 301
  end

  def policy
    settings = Rails.application.config_for(:settings)

    respond_to do |format|
      format.json { render json: { 
                              tos_url: ActionController::Base.helpers.asset_path('tos.rtf'), 
                              tos_version: settings['tos_version'],
                              tos_last_updated: settings['tos_last_updated'],
                              policy_url: ActionController::Base.helpers.asset_path('privacy.rtf'), 
                              policy_version: settings['policy_version'],
                              policy_last_updated: settings['policy_last_updated'] 
                            }, 
                           status: :ok }
    end
  end

  def missed_messages
    chat = Chat.find(params[:chat_id])

    if from_iphone?
      redirect_to app_launcher_url(path: "/messages/#{chat.id}")
    else
      receiver = User.find(params[:receiver_id])
      if receiver.advisor?
        sender = User.find(params[:sender_id])
        client = receiver.clients_as_advisor.where(consumer_id: sender.id).first
        redirect_to client_root_url(client, 'messages')
      else
        # since web app is not available for client
        # redirect to app_launcher_url so they can launch app or view itunes page
        redirect_to app_launcher_url
      end
    end
  end

  def app_launcher
    @app_path = params[:path].present? ? params[:path] : ''
    respond_to do |format|
      format.html { render layout: 'simple' }
    end
  end

end