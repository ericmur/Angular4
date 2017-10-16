class ProcessSignupReferralJob < ActiveJob::Base
  queue_as :default

  def perform(user_id)
    user = User.find(user_id)
    user.process_signup_referral_without_delay
  end
end