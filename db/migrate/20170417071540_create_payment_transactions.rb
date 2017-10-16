class CreatePaymentTransactions < ActiveRecord::Migration
  def change
    create_table :payment_transactions do |t|
      t.money :amount
      t.timestamp :date
      t.references :user, index: true, foreign_key: true

    end
  end
end
