class CreateUserCredits < ActiveRecord::Migration
  def change
    create_table :user_credits do |t|
      t.references :user, index: true, foreign_key: true
      t.integer :fax_credit, default: 0

      t.timestamps null: false
    end
  end
end
