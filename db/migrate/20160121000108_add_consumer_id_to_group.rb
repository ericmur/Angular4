class AddConsumerIdToGroup < ActiveRecord::Migration
  def change
    add_column :standard_groups, :consumer_id, :integer
  end
end
