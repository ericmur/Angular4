class CreateCategory < ActiveRecord::Migration
  def change
    create_table :categories do |t|
      t.belongs_to :standard_category
      t.integer :owner_id
      t.string :name
    end
  end
end
