class CreateStandardGroups < ActiveRecord::Migration
  def change
    create_table :standard_groups do |t|
      t.string  :name
      t.timestamps
    end

    add_index :standard_groups, :name, unique: true
  end
end
