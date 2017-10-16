class CreateFavorites < ActiveRecord::Migration
  def change
    create_table :favorites do |t|
      t.integer :document_id
      t.integer :consumer_id
      t.integer :rank
      t.timestamps null: false
    end

    add_index :favorites, [:consumer_id, :document_id], :unique => true
  end
end
