class CreateUserCreditPromotions < ActiveRecord::Migration
  def change
    create_table :user_credit_promotions do |t|
      t.references :user, index: true, foreign_key: true
      t.integer :given_by_id, index: true
      t.float :credit_value, default: 0.0
      t.string :promotion_type

      t.timestamps null: false
    end
  end
end
