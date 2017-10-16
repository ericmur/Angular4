class Api::Mobile::V2::BusinessInformationsController < Api::Mobile::V2::ApiController
  def create
    render status: 422, json: { errors: ['We do not support adding clients in this version of the app. Please upgrade.'] }

    # @business_information = BusinessInformation.new(business_information_params)
    # if @business_information.save
    #   @user = current_user
    #   @user.business_information = @business_information
    #   @user.standard_category_id = @business_information.standard_category_id
    #   @user.save!
    #   render status: 200, json: @business_information, serializer: ::Api::Mobile::V2::BusinessInformationSerializer, root: 'business_information'
    # else
    #   render status: 422, json: { errors: business_information.errors.full_messages }
    # end
  end

  # private

  # def business_information_params
  #   params.require(:business_information).permit(:name, :phone, :email, :address_street, :address_city, :address_state, :address_zip, :standard_category_id)
  # end
end