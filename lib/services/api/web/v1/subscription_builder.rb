class Api::Web::V1::SubscriptionBuilder
  def initialize(current_user, params)
    @current_user = current_user
    @params  = params
  end

  def create_subscription(customer_id)
    current_sub = Subscription.find_by(user_id: @current_user.id)
    if current_sub
      subscription = Stripe::Subscription.retrieve(current_sub.subscription_token)
      subscription.plan = current_sub.get_plan_id(@current_user, @params[:subscription_type])
      subscription.save
      current_sub.subscription_type = current_sub.get_sub_type(@params[:subscription_type])
      current_sub.subscription_expires_at = Time.at(subscription.current_period_end)
      current_sub.save
    else
      new_sub = Subscription.new()
      subscription = Stripe::Subscription.create customer: customer_id, plan: new_sub.get_plan_id(@current_user, @params[:subscription_type])
      new_sub.subscription_type = new_sub.get_sub_type(@params[:subscription_type])
      new_sub.subscription_expires_at = Time.at(subscription.current_period_end)
      new_sub.subscription_token = subscription.id
      new_sub.user_id = @current_user.id
      new_sub.save
    end
  end
end