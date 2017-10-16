class CreateDimensions < ActiveRecord::Migration
  def change
    create_table :dimensions do |t|
      t.float :width
      t.float :height
      t.string :unit
      t.string :name
      t.timestamps null: false
    end
  end
end
