class UserCredit < ActiveRecord::Base
  belongs_to :user
  has_many :transactions, class_name: 'UserCreditTransaction', dependent: :destroy
  validates :fax_credit, presence: true

  def has_available_fax_credit?(number_of_pages)
    return fax_credit >= number_of_pages
  end

  def purchase_pages_credit!(transactionable, balance, transaction_identifier, transaction_date)
    transaction = self.transactions.build(transactionable: transactionable, pages_balance: balance,
      transaction_identifier: transaction_identifier, transaction_date: transaction_date)
    transaction.save!
    transaction.complete!
  end

  def purchase_fax_credit!(transactionable, balance, transaction_identifier, transaction_date)
    transaction = self.transactions.build(transactionable: transactionable, fax_balance: balance,
      transaction_identifier: transaction_identifier, transaction_date: transaction_date)
    transaction.save!
    transaction.complete!
  end

  def buy_dollar_credit!(transactionable, balance, transaction_identifier, transaction_date)
    transaction = self.transactions.build(transactionable: transactionable, dollar_balance: balance,
      transaction_identifier: transaction_identifier, transaction_date: transaction_date)
    transaction.save!
    transaction.complete!
  end

  def authorize_fax_credit!(transactionable, balance)
    balance = balance * -1 if balance > 0 # ensure negative value
    transaction = self.transactions.build(transactionable: transactionable, fax_balance: balance)
    transaction.save!
    transaction.authorize!
  end
end
