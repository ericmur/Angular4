class Api::Web::V1::CreditCardsController < Api::Web::V1::ApiController

  def index
    @credit_cards = current_advisor.credit_cards

    render status: 200, json: @credit_cards
  end

  def show
  end

  def create
    service = ::Api::Web::V1::CreditCardBuilder.new(current_advisor, credit_params, params)
    if CreditCard.find_by(user_id: current_advisor.id)
      @credit = service.update_card
    else
      @credit = service.create_card
    end

    if @credit
      render status: 200, json: @credit
    else
      render status: 422, json: { errors: @credit.errors.full_messages }
    end
  end

  def update
  end

  private

  def credit_params
    params.require(:credit).permit(:stripe_token, :holder_name, :company, :bill_address,
      :city, :state, :zip, :country)
  end

end
