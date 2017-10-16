class CreateConsumerGroups < ActiveRecord::Migration
  def change
    create_table :consumer_groups do |t|
      t.integer :consumer_id
      t.integer :group_id
      t.timestamps
    end
  end
end
