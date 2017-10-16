class Api::Web::V1::ClientsController < Api::Web::V1::ApiController
  before_action :set_clients,    only: :index
  before_action :search_clients, only: :search

  def index
    render status: 200, json: @clients_query.get_clients, each_serializer: ::Api::Web::V1::ClientSerializer,
    meta: { pages_count: @clients_query.get_total_pages }
  end

  def show
    client = current_advisor.clients_as_advisor.find_by(id: params[:id])

    if client
      render status: 200, json: client, serializer: ::Api::Web::V1::ClientSerializer
    else
      render status: 404, json: {}
    end
  end

  def create
    client_creation_service = ::Api::Web::V1::ClientCreationService.new(current_advisor, client_params)
    client_creation_service.create_client_and_invitation

    if client_creation_service.errors.any?
      render status: 422, json: client_creation_service.errors
    else
      client_creation_service.client.generate_folder_settings(current_advisor)
      render status: 201, json: client_creation_service.client
    end
  end

  def search
    render status: 200, json: @clients, each_serializer: ::Api::Web::V1::ClientSerializer
  end

  private

  def set_clients
    @clients_query = ::Api::Web::V1::ClientsQuery.new(current_advisor, params)
  end

  def search_clients
    @clients = ::Api::Web::V1::ClientsQuery.new(current_advisor, params).search_clients
  end

  def client_params
    params.require(:client).permit(:email, :phone, :name,
      invitation: [:email, :phone, :email_invitation, :text_invitation])
  end
end
