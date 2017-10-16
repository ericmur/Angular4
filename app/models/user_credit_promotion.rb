class UserCreditPromotion < ActiveRecord::Base
  SIGNUP_CREDITS_BONUS=25
  BUSINESS_SUBSCRIPTION_CREDITS_BONUS=9.99
  FAMILY_SUBSCRIPTION_CREDITS_BONUS=2.99

  SIGNUP_PROMOTION='SIGNUP-PROMOTION'
  BUSINESS_SUBSCRIPTION_PROMOTION='BUSINESS-SUBSCRIPTION-PROMOTION'
  FAMILY_SUBSCRIPTION_PROMOTION='FAMILY-SUBSCRIPTION-PROMOTION'

  belongs_to :user
  belongs_to :given_by, class_name: 'User', foreign_key: 'given_by_id'

  scope :given_by, -> (user) { where(given_by: user) }
  scope :for_promotion_type, -> (promotion_type) { where(promotion_type: promotion_type) }

  validates :credit_value, presence: true
  validates :promotion_type, presence: true

  def self.get_credit_bonus_for(promotion_type)
    if promotion_type == SIGNUP_PROMOTION
      return SIGNUP_CREDITS_BONUS
    elsif promotion_type == BUSINESS_SUBSCRIPTION_PROMOTION
      return BUSINESS_SUBSCRIPTION_CREDITS_BONUS
    elsif promotion_type == FAMILY_SUBSCRIPTION_PROMOTION
      return FAMILY_SUBSCRIPTION_CREDITS_BONUS
    end
    nil
  end
end
