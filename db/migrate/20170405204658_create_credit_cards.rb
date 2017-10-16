class CreateCreditCards < ActiveRecord::Migration
  def change
    create_table :credit_cards do |t|
      t.string :stripe_token
      t.string :holder_name
      t.string :company
      t.string :bill_address
      t.string :city
      t.string :state
      t.string :zip
      t.string :country
      t.references :user, index: true, foreign_key: true

      t.timestamps null: false
    end
  end
end
