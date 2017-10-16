class ReferralCode < ActiveRecord::Base
  belongs_to :user

  validates :code, presence: true
  validates :code, uniqueness: true
end
