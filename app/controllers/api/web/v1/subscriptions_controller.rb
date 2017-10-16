class Api::Web::V1::SubscriptionsController < Api::Web::V1::ApiController

  def index
    @subscription = current_advisor.subscriptions
    render status: 200, json: @subscription
  end

  def create
  	acc_type = ConsumerAccountType.find_by(display_name: params[:subscription][:account_type]).id
  	current_advisor.update(consumer_account_type_id: acc_type, current_workspace_id: acc_type)
  	my_card = CreditCard.find_by(user_id: current_advisor.id)
  	if my_card.present?
  		if params[:subscription][:account_type] == "Business"
				cur_workspace_id = ConsumerAccountType::BUSINESS
  		else
				cur_workspace_id = ConsumerAccountType::INDIVIDUAL
  		end
  		current_advisor.current_workspace_id = cur_workspace_id
    	@sub_service = ::Api::Web::V1::SubscriptionBuilder.new(current_advisor, params[:subscription])
 			@sub_service.create_subscription(my_card.customer_token)
      render status: 200, json: current_advisor.subscriptions
		else
      render status: 422, json: { errors: "You haven't register your credit card." }
		end  
  end
end
