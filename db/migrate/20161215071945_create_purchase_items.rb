class CreatePurchaseItems < ActiveRecord::Migration
  def change
    create_table :purchase_items do |t|
      t.string :name, index: true
      t.string :product_identifier, index: true
      t.decimal :price, default: 0
      t.integer :fax_credit_value, default: 0
      t.boolean :enabled, default: true
      t.datetime :deleted_at

      t.timestamps null: false
    end
  end
end
