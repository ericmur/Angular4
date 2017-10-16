class CreateUserAccesses < ActiveRecord::Migration
  def change
    create_table :user_accesses do |t|
      t.integer :user_id
      t.integer :accessor_id
      t.timestamps
    end
    
    add_index :user_accesses, [:user_id, :accessor_id]
  end
end
