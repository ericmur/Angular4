class CreateWorkflows < ActiveRecord::Migration
  def change
    create_table :workflows do |t|
      t.string  :name
      t.string  :kind
      t.integer :advisor_id, index: true

      t.timestamps null: false
    end
  end
end
