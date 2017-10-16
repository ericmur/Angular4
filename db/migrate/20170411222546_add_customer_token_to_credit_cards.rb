class AddCustomerTokenToCreditCards < ActiveRecord::Migration
  def change
    add_column :credit_cards, :customer_token, :string
  end
end
