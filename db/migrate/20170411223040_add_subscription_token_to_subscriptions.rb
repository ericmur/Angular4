class AddSubscriptionTokenToSubscriptions < ActiveRecord::Migration
  def change
    add_column :subscriptions, :subscription_token, :string
  end
end
