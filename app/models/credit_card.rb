class CreditCard < ActiveRecord::Base
  belongs_to :user

  validates :stripe_token, presence: true
  validates :user_id, presence: true
end
