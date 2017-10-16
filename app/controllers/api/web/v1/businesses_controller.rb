class Api::Web::V1::BusinessesController < Api::Web::V1::ApiController

  def index
    @businesses = current_advisor.businesses

    render status: 200, json: @businesses, each_serializer: ::Api::Web::V1::BusinessSerializer
  end

  def show
    @business = Business.find(params[:id])
    render status: 200, json: @business, serializer: ::Api::Web::V1::BusinessSerializer
  end

  def create
    service = ::Api::Web::V1::BusinessBuilder.new(current_advisor, business_params, params)
    @business = service.create_business

    if @business.persisted? && @business.errors.empty?
      render status: 200, json: @business, serializer: ::Api::Web::V1::BusinessSerializer
    else
      render status: 422, json: { errors: @business.errors.full_messages }
    end
  end

  def update
  end

  def get_entity_types
    render status: 200, json: Business::ENTITY_TYPES.map { |e| {:text => e} },
      root: :entity_type
  end

  private

  def business_params
    params.require(:business).permit(:name, :entity_type, :address_state, :address_street,
      :address_zip, :standard_category_id, :address_city)
  end

end
