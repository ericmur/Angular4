class CreateUserCreditTransactions < ActiveRecord::Migration
  def change
    create_table :user_credit_transactions do |t|
      t.references :user_credit, index: true, foreign_key: true
      t.references :transactionable, polymorphic: true
      t.integer :fax_balance, default: 0 # use integer for now.
      t.string :state, index: true
      t.string :transaction_identifier # SKPayment:transactionIdentifier
      t.datetime :transaction_date # SKPayment:transactionDate
      t.timestamps null: false
    end
    add_index :user_credit_transactions, [:transactionable_id, :transactionable_type], name: 'idx_credit_transactionable'
  end
end
