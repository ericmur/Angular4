class Api::Web::V1::CreditCardBuilder
  def initialize(current_user, credit_params, params)
    @current_user = current_user
    @credit_params = credit_params
    @params  = params
    @sub_service = ::Api::Web::V1::SubscriptionBuilder.new(current_user, params[:credit])
  end

  def create_card
 		customer = Stripe::Customer.create email: @current_user.email, source: @credit_params[:stripe_token]
 		if @params[:credit][:subscription_type].present?
 			@sub_service.create_subscription(customer.id)
 		end
 		@current_user.credit_cards.create(@credit_params.merge(:customer_token => customer.id))
  end

  def update_card
  	my_card = CreditCard.find_by(user_id: @current_user.id)
 		my_card.stripe_token = @credit_params[:stripe_token]
 		customer = Stripe::Customer.retrieve(my_card.customer_token)
 		customer.source = @credit_params[:stripe_token]
 		customer.save
 		if @params[:credit][:subscription_type].present?
 			@sub_service.create_subscription(customer.id)
 		end
 		my_card.save!
  end
end