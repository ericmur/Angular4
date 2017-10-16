class CreateParticipants < ActiveRecord::Migration
  def change
    create_table :participants do |t|
      t.integer :workflow_id
      t.integer :user_id

      t.timestamps null: false
    end
    add_index :participants, :workflow_id
    add_index :participants, :user_id
  end
end
