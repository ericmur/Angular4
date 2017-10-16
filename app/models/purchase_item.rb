# Fields:
# name: Value will be shown on iPhone App.
# discount: Value will be shown on iPhone App.
# product_identifier: ProductID in itunesconnect.
# price: Used for display on iPhone App and for offline purchase if needed.
# fax_credit_value: Amount of fax_credit should be given after successful purchase.
class PurchaseItem < ActiveRecord::Base
  has_many :transactions, class_name: 'UserCreditTransaction', as: :transactionable # Will not set dependent: destroy/nullify to maintain histories.
  validates :name, presence: true
  validates :product_identifier, presence: true
  validates :price, presence: true
  validates :fax_credit_value, presence: true
end
