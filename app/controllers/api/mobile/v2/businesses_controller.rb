class Api::Mobile::V2::BusinessesController < Api::Mobile::V2::ApiController

  def index
    @businesses = Business.joins(:business_partners).where(business_partners: { user: current_user })

    # get the business shared to non-business account
    business_ids = Document.joins({:business_documents => :business}).accessible_by_me(current_user).pluck("DISTINCT business_id").reject(&:nil?)
    @businesses = @businesses.union(Business.where(id: business_ids))

    render status: 200, json: @businesses, each_serializer: ::Api::Mobile::V2::BusinessSerializer
  end

  def show
    @business = Business.find(params[:id])
    render status: 200, json: @business, serializer: ::Api::Mobile::V2::BusinessSerializer
  end

  def create
    service = ::Api::Mobile::V2::BusinessBuilder.new(current_user, business_params, params)
    @business = service.create_business

    if @business.persisted? && @business.errors.empty?
      render status: 200, json: @business, serializer: ::Api::Mobile::V2::BusinessSerializer
    else
      render status: 422, json: { errors: @business.errors.full_messages }
    end
  end

  private

  def business_params
    params.require(:business).permit(:name, :entity_type, :address_state, :address_street,
      :address_zip, :standard_category_id, :address_city)
  end

end