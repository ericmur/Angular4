class CreateRequests < ActiveRecord::Migration
  def change
    create_table :requests do |t|
      t.integer    :workflow_id, index: true
      t.references :requestionable, polymorphic: true, index: true

      t.timestamps null: false
    end
  end
end
