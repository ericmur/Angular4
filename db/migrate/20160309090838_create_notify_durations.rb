class CreateNotifyDurations < ActiveRecord::Migration
  def change
    create_table :notify_durations do |t|
      t.references :standard_document_field, index: true, foreign_key: true
      t.float :amount
      t.string :unit

      t.timestamps null: false
    end
  end
end
