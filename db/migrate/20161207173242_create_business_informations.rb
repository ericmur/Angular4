class CreateBusinessInformations < ActiveRecord::Migration
  def change
    create_table :business_informations do |t|
      t.string :name
      t.string :phone
      t.string :email
      t.string :address_street
      t.string :address_city
      t.string :address_state
      t.string :address_zip
      t.references :standard_category, index: true, foreign_key: true

      t.timestamps null: false
    end
  end
end
