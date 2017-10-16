class ProcessSubscriptionReferralJob < ActiveJob::Base
  queue_as :default

  def perform(subscription_id)
    subscription = Subscription.find(subscription_id)
    subscription.process_subscription_referral_without_delay
  end
end