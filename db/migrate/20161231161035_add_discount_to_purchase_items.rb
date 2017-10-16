class AddDiscountToPurchaseItems < ActiveRecord::Migration
  def change
    add_column :purchase_items, :discount, :float, default: 0.0
  end
end
