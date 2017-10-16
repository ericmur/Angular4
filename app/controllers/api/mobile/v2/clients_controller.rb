class Api::Mobile::V2::ClientsController < Api::Mobile::V2::ApiController
  #For show we might get a non-advisor's request too. This can happen when a document is co-owned by a user A and a non-connected client of another user B (advisor).
  #In this case, user A will need to call show action to get the clients info.
  before_action :verify_current_user_is_advisor, except: [:show]
  before_action :load_client, only: [:update, :invite, :destroy, :unlink]

  def show
    @client = Client.find(params[:id])
    render status: 200, json: @client, serializer: ::Api::Mobile::V2::ClientSerializer, root: 'client'
  end

  def create
    client_creation_service = ::Api::Web::V1::ClientCreationService.new(current_user, client_params)
    client_creation_service.create_client_and_invitation

    if client_creation_service.errors.any?
      render status: 422, json: { errors: client_creation_service.errors.map{|_, v| v }.flatten }
    else
      client_creation_service.client.generate_folder_settings(current_user)
      render status: 200, json: client_creation_service.client, serializer: ::Api::Mobile::V2::ClientSerializer, root: 'client'
    end
  end

  def update
    if @client.update(client_params)
      render status: 200, json: @client, serializer: ::Api::Mobile::V2::ClientSerializer, root: 'client'
    else
      render status: 422, json: { errors: @client.errors.full_messages }
    end
  end

  def destroy
    @client.destroy
    DocumentCacheService.update_cache([:standard_folder, :standard_document, :document, :folder_setting], [current_user.id])
    render status: 200, nothing: true
  end

  def unlink
    if @client.unlink!
      render status: 200, nothing: true
    else
      render status: 422, json: { errors: @client.errors.full_messages }
    end
  end

  private

  def verify_current_user_is_advisor
    unless current_user.standard_category.present?
      render status: 422, json: ["You do not have the permission to access this page"]
    end
  end

  def load_client
    @client = current_user.clients_as_advisor.find(params[:id])
  end

  def client_params
    params.require(:client).permit(:email, :phone, :name,
      invitation: [:email, :phone, :email_invitation, :text_invitation])
  end
end