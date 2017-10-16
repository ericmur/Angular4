class CreateGroups < ActiveRecord::Migration
  def change
    create_table :groups do |t|
      t.integer  :standard_group_id
      t.integer  :owner_id
      t.timestamps
    end

    add_index :groups, [:owner_id, :standard_group_id]
  end
end
