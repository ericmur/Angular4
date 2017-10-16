class AddPricingToConsumerAccountTypes < ActiveRecord::Migration
  def change
    add_column :consumer_account_types, :monthly_pricing, :money
    add_column :consumer_account_types, :annual_pricing, :money
  end
end
