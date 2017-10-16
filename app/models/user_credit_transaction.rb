class UserCreditTransaction < ActiveRecord::Base
  include AASM

  belongs_to :user_credit
  belongs_to :transactionable, polymorphic: true
  validates :fax_balance, presence: true
  validates :dollar_balance, presence: true

  after_save :calculate_user_credit
  after_destroy :calculate_user_credit

  aasm column: :state do
    state :pending, initial: true
    state :authorized
    state :completed
    state :failed

    event :authorize  do
      transitions from: [:pending], to: :authorized
    end

    event :complete do #Failed to completed is when we retry a failed job
      transitions from: [:pending, :authorized, :failed], to: :completed
    end

    event :fail do
      transitions from: [:pending, :authorized], to: :failed
    end
  end

  def calculate_user_credit
    fax_credit = user_credit.transactions.where.not(state: :failed).pluck(:fax_balance).sum
    dollar_credit = user_credit.transactions.where.not(state: :failed).pluck(:dollar_balance).sum
    pages_credit = user_credit.transactions.where.not(state: :failed).pluck(:pages_balance).sum

    user_credit.fax_credit = fax_credit
    user_credit.dollar_credit = dollar_credit
    user_credit.pages_credit = pages_credit
    user_credit.save
  end
end
