class BusinessDocument < ActiveRecord::Base
  belongs_to :business
  belongs_to :document

  validates :business_id, presence: true
end
