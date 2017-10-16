class AddStatisticsIndexes < ActiveRecord::Migration
  def change
    add_index :users, :created_at
    add_index :pages, :created_at
  end
end
