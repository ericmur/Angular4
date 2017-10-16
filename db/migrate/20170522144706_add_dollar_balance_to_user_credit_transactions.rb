class AddDollarBalanceToUserCreditTransactions < ActiveRecord::Migration
  def change
    add_column :user_credit_transactions, :dollar_balance, :float, default: 0.0
  end
end
