class AddDollarCreditToUserCredits < ActiveRecord::Migration
  def change
  	add_column :user_credits, :dollar_credit, :float, default: 0.0
  end
end
