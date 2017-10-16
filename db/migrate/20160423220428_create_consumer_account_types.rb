class CreateConsumerAccountTypes < ActiveRecord::Migration
  def change
    create_table :consumer_account_types do |t|
      t.string :display_name, :null => false
      t.timestamps null: false
      t.index :display_name, unique: true
    end
  end
end
