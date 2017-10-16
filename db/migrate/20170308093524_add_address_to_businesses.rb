class AddAddressToBusinesses < ActiveRecord::Migration
  def change
    add_column :businesses, :business_type, :string
    add_column :businesses, :address_street, :string
    add_column :businesses, :address_state, :string
    add_column :businesses, :address_zip, :string
    add_column :businesses, :address_city, :string
    add_reference :businesses, :standard_category, index: true, foreign_key: true
  end
end
