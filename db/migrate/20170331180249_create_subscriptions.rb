class CreateSubscriptions < ActiveRecord::Migration
  def change
    create_table :subscriptions do |t|
      t.string :subscription_type
      t.datetime :subscription_expires_at
      t.references :user, index: true, foreign_key: true

      t.timestamps null: false
    end
  end
end
