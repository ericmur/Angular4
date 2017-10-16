class BusinessPartner < ActiveRecord::Base
  belongs_to :business
  belongs_to :user

  validates :user_id, presence: true
end
