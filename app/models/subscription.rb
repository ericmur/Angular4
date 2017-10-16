class Subscription < ActiveRecord::Base
  PLAN_MONTHLY = 'Monthly'
  PLAN_ANNUAL = 'Annual'

  PLAN_BIZ_MONTH = 'biz-monthly'
  PLAN_BIZ_YEAR = 'biz-annual'
  PLAN_FAMILY_MONTH = 'family-monthly'
  PLAN_FAMILY_YEAR = 'family-annual'
  belongs_to :user

  validates :subscription_type, presence: true
  validates :subscription_expires_at, presence: true

  after_create :process_subscription_referral

  def get_plan_id(current_user, sub_type)
  	if current_user.consumer_account_type_id == ConsumerAccountType::BUSINESS
  		if sub_type == "year"
  			return PLAN_BIZ_YEAR
  		end
  		if sub_type == "month"
  			return PLAN_BIZ_MONTH
  		end
		end  		
  	if current_user.consumer_account_type_id == ConsumerAccountType::INDIVIDUAL
  		if sub_type == "year"
  			return PLAN_FAMILY_YEAR
  		end
  		if sub_type == "month"
  			return PLAN_FAMILY_MONTH
  		end
		end  		
  end

  def get_sub_type(sub_type)
		if sub_type == "year"
			return PLAN_ANNUAL
		end
		if sub_type == "month"
			return PLAN_MONTHLY
		end
  end

  def process_subscription_referral
    ProcessSubscriptionReferralJob.perform_later(self.id)
  end

  def process_subscription_referral_without_delay
    return unless user.present? && user.referrer.present?

    if subscription_type.match(/biz/)
      promotion_type = UserCreditPromotion::BUSINESS_SUBSCRIPTION_PROMOTION
    else
      promotion_type = UserCreditPromotion::FAMILY_SUBSCRIPTION_PROMOTION
    end

    credit_value = UserCreditPromotion.get_credit_bonus_for(promotion_type)

    ActiveRecord::Base.transaction do
      begin
        referrer = user.referrer
        unless referrer.user_credit_promotions.given_by(user).for_promotion_type(promotion_type).exists?
          subs_promo = referrer.user_credit_promotions.build(given_by: user, credit_value: credit_value, promotion_type: promotion_type)
          subs_promo.save!

          user_credit = referrer.user_credit
          user_credit.buy_dollar_credit!(subs_promo, subs_promo.credit_value, promotion_type, self.created_at)
        end
      rescue => e
        raise ActiveRecord::Rollback
      end
    end
  end
end
