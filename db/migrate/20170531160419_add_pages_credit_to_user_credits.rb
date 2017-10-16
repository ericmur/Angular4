class AddPagesCreditToUserCredits < ActiveRecord::Migration
  def change
    add_column :user_credits, :pages_credit, :integer, default: 0
    add_column :user_credit_transactions, :pages_balance, :integer, default: 0
  end
end
